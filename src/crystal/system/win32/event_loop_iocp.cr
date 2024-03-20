require "c/ioapiset"
require "crystal/system/print_error"

# :nodoc:
class Crystal::Iocp::EventLoop < Crystal::EventLoop
  @queue = Deque(Crystal::Iocp::Event).new

  # Returns the base IO Completion Port
  getter iocp : LibC::HANDLE do
    create_completion_port(LibC::INVALID_HANDLE_VALUE, nil)
  end

  def create_completion_port(handle : LibC::HANDLE, parent : LibC::HANDLE? = iocp)
    iocp = LibC.CreateIoCompletionPort(handle, parent, nil, 0)
    if iocp.null?
      raise IO::Error.from_winerror("CreateIoCompletionPort")
    end
    if parent
      # all overlapped operations may finish synchronously, in which case we do
      # not reschedule the running fiber; the following call tells Win32 not to
      # queue an I/O completion packet to the associated IOCP as well, as this
      # would be done by default
      if LibC.SetFileCompletionNotificationModes(handle, LibC::FILE_SKIP_COMPLETION_PORT_ON_SUCCESS) == 0
        raise IO::Error.from_winerror("SetFileCompletionNotificationModes")
      end
    end
    iocp
  end

  # Runs the event loop.
  def run_once : Nil
    next_event = @queue.min_by(&.wake_at)

    if next_event
      now = Time.monotonic

      if next_event.wake_at > now
        sleep_time = next_event.wake_at - now
        timed_out = Iocp::EventLoop.wait_queued_completions(sleep_time.total_milliseconds) do |fiber|
          Crystal::Scheduler.enqueue fiber
        end

        return unless timed_out
      end

      dequeue next_event

      fiber = next_event.fiber

      unless fiber.dead?
        if next_event.timeout? && (select_action = fiber.timeout_select_action)
          fiber.timeout_select_action = nil
          select_action.time_expired(fiber)
        else
          Crystal::Scheduler.enqueue fiber
        end
      end
    else
      Crystal::System.print_error "Warning: No runnables in scheduler. Exiting program.\n"
      ::exit
    end
  end

  def enqueue(event : Crystal::Iocp::Event)
    unless @queue.includes?(event)
      @queue << event
    end
  end

  def dequeue(event : Crystal::Iocp::Event)
    @queue.delete(event)
  end

  # Create a new resume event for a fiber.
  def create_resume_event(fiber : Fiber) : Crystal::EventLoop::Event
    Crystal::Iocp::Event.new(fiber)
  end

  def create_timeout_event(fiber) : Crystal::EventLoop::Event
    Crystal::Iocp::Event.new(fiber, timeout: true)
  end

  def read(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32
    handle = file.windows_handle
    overlapped_operation(handle, "ReadFile", file.read_timeout) do |overlapped|
      ret = LibC.ReadFile(handle, slice, slice.size, out byte_count, overlapped)
      {ret, byte_count}
    end.to_i32
  end

  def read(socket : ::Socket, slice : Bytes) : Int32
    wsabuf = wsa_buffer(slice)

    overlapped_read(socket, "WSARecv", connreset_is_error: false) do |overlapped|
      flags = 0_u32
      ret = LibC.WSARecv(socket.fd, pointerof(wsabuf), 1, out bytes_received, pointerof(flags), overlapped, nil)
      {ret, bytes_received}
    end.to_i32
  end

  def write(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32
    handle = file.windows_handle

    overlapped_operation(handle, "WriteFile", file.write_timeout, writing: true) do |overlapped|
      ret = LibC.WriteFile(handle, slice, slice.size, out byte_count, overlapped)
      {ret, byte_count}
    end.to_i32
  end

  def write(socket : ::Socket, slice : Bytes) : Int32
    wsabuf = wsa_buffer(slice)

    bytes = overlapped_write(socket, "WSASend") do |overlapped|
      ret = LibC.WSASend(socket.fd, pointerof(wsabuf), 1, out bytes_sent, 0, overlapped, nil)
      {ret, bytes_sent}
    end

    bytes.to_i32
  end

  private def overlapped_write(socket, method, &)
    wsa_overlapped_operation(socket.fd, method, socket.write_timeout) do |operation|
      yield operation
    end
  end

  private def overlapped_read(socket, method, *, connreset_is_error = true, &)
    wsa_overlapped_operation(socket.fd, method, socket.read_timeout, connreset_is_error) do |operation|
      yield operation
    end
  end

  def accept(socket : ::Socket) : Socket::Handle?
    client_socket = socket.create_handle(socket.family, socket.type, socket.protocol, socket.blocking)
    socket.initialize_handle(client_socket)

    if system_accept(socket, client_socket)
      client_socket
    else
      LibC.closesocket(client_socket)

      nil
    end
  end

  protected def system_accept(socket, client_socket) : Bool
    address_size = sizeof(LibC::SOCKADDR_STORAGE) + 16
    buffer_size = 0
    output_buffer = Bytes.new(address_size * 2 + buffer_size)

    success = overlapped_accept(socket, "AcceptEx") do |overlapped|
      # This is: LibC.AcceptEx(fd, client_socket, output_buffer, buffer_size, address_size, address_size, out received_bytes, overlapped)
      received_bytes = uninitialized UInt32
      Crystal::System::Socket.accept_ex.call(socket.fd, client_socket,
        output_buffer.to_unsafe.as(Void*), buffer_size.to_u32!,
        address_size.to_u32!, address_size.to_u32!, pointerof(received_bytes), overlapped)
    end

    return false unless success

    # AcceptEx does not automatically set the socket options on the accepted
    # socket to match those of the listening socket, we need to ask for that
    # explicitly with SO_UPDATE_ACCEPT_CONTEXT
    socket.system_setsockopt client_socket, LibC::SO_UPDATE_ACCEPT_CONTEXT, socket.fd

    true
  end

  private def overlapped_accept(socket, method, &)
    OverlappedOperation.run(socket.fd) do |operation|
      result = yield operation.start

      if result == 0
        case error = WinError.wsa_value
        when .wsa_io_pending?
          # the operation is running asynchronously; do nothing
        else
          return false
        end
      else
        operation.synchronous = true
        return true
      end

      unless schedule_overlapped(socket.read_timeout)
        raise IO::TimeoutError.new("#{method} timed out")
      end

      operation.wsa_result(socket.fd) do |error|
        case error
        when .wsa_io_incomplete?, .wsaenotsock?
          return false
        end
      end

      true
    end
  end

  def connect(socket : ::Socket, addr : ::Socket::Addrinfo | ::Socket::Address, timeout : ::Time::Span?, & : IO::Error ->) : Nil
    if socket.type.stream?
      connect_stream(socket, addr, timeout) { |error| yield error }
    else
      connect_connectionless(socket.fd, addr, timeout) { |error| yield error }
    end
  end

  private def connect_stream(socket, addr, timeout, &)
    address = LibC::SockaddrIn6.new
    address.sin6_family = socket.family
    address.sin6_port = 0
    unless LibC.bind(socket.fd, pointerof(address).as(LibC::Sockaddr*), sizeof(LibC::SockaddrIn6)) == 0
      return yield ::Socket::BindError.from_wsa_error("Could not bind to '*'")
    end

    error = overlapped_connect(socket, "ConnectEx") do |overlapped|
      # This is: LibC.ConnectEx(fd, addr, addr.size, nil, 0, nil, overlapped)
      Crystal::System::Socket.connect_ex.call(socket.fd, addr.to_unsafe, addr.size, Pointer(Void).null, 0_u32, Pointer(UInt32).null, overlapped)
    end

    if error
      return yield error
    end

    # from https://learn.microsoft.com/en-us/windows/win32/winsock/sol-socket-socket-options:
    #
    # > This option is used with the ConnectEx, WSAConnectByList, and
    # > WSAConnectByName functions. This option updates the properties of the
    # > socket after the connection is established. This option should be set
    # > if the getpeername, getsockname, getsockopt, setsockopt, or shutdown
    # > functions are to be used on the connected socket.
    optname = LibC::SO_UPDATE_CONNECT_CONTEXT
    if LibC.setsockopt(socket.fd, LibC::SOL_SOCKET, optname, nil, 0) == LibC::SOCKET_ERROR
      return yield ::Socket::Error.from_wsa_error("setsockopt #{optname}")
    end
  end

  private def overlapped_connect(socket, method, &)
    OverlappedOperation.run(socket.fd) do |operation|
      result = yield operation.start

      if result == 0
        case error = WinError.wsa_value
        when .wsa_io_pending?
          # the operation is running asynchronously; do nothing
        when .wsaeaddrnotavail?
          return ::Socket::ConnectError.from_os_error("ConnectEx", error)
        else
          return ::Socket::Error.from_os_error("ConnectEx", error)
        end
      else
        operation.synchronous = true
        return nil
      end

      schedule_overlapped(socket.read_timeout || 1.seconds)

      operation.wsa_result(socket.fd) do |error|
        case error
        when .wsa_io_incomplete?, .wsaeconnrefused?
          return ::Socket::ConnectError.from_os_error(method, error)
        when .error_operation_aborted?
          # FIXME: Not sure why this is necessary
          return ::Socket::ConnectError.from_os_error(method, error)
        end
      end

      nil
    end
  end

  private def connect_connectionless(fd, addr, timeout, &)
    ret = LibC.connect(fd, addr, addr.size)
    if ret == LibC::SOCKET_ERROR
      yield ::Socket::Error.from_wsa_error("connect")
    end
  end

  def send(socket : ::Socket, slice : Bytes) : Int32
    wsabuf = wsa_buffer(slice)

    bytes = overlapped_write(socket, "WSASend") do |overlapped|
      ret = LibC.WSASend(socket.fd, pointerof(wsabuf), 1, out bytes_sent, 0, overlapped, nil)
      {ret, bytes_sent}
    end

    bytes.to_i32
  end

  def send_to(socket : ::Socket, slice : Bytes, addr : ::Socket::Address) : Int32
    wsabuf = wsa_buffer(slice)
    bytes_written = overlapped_write(socket, "WSASendTo") do |overlapped|
      ret = LibC.WSASendTo(socket.fd, pointerof(wsabuf), 1, out bytes_sent, 0, addr, addr.size, overlapped, nil)
      {ret, bytes_sent}
    end
    raise ::Socket::Error.from_wsa_error("Error sending datagram to #{addr}") if bytes_written == -1

    # to_i32 is fine because string/slice sizes are an Int32
    bytes_written.to_i32
  end

  def receive_from(socket : ::Socket, slice : Bytes) : Tuple(Int32, ::Socket::Address)
    sockaddr = Pointer(LibC::SOCKADDR_STORAGE).malloc.as(LibC::Sockaddr*)
    # initialize sockaddr with the initialized family of the socket
    copy = sockaddr.value
    copy.sa_family = socket.family
    sockaddr.value = copy

    addrlen = sizeof(LibC::SOCKADDR_STORAGE)

    wsabuf = wsa_buffer(slice)

    flags = 0_u32
    bytes_read = overlapped_read(socket, "WSARecvFrom") do |overlapped|
      ret = LibC.WSARecvFrom(socket.fd, pointerof(wsabuf), 1, out bytes_received, pointerof(flags), sockaddr, pointerof(addrlen), overlapped, nil)
      {ret, bytes_received}
    end

    {bytes_read.to_i32, ::Socket::Address.from(sockaddr, addrlen)}
  end

  def receive(socket : ::Socket, slice : Bytes) : Int32
    receive(socket, slice)[0]
  end

  def close(resource) : Nil
  end

  def close(file : ::File::Descriptor) : Nil
    LibC.CancelIoEx(file.windows_handle, nil) unless file.system_blocking?
  end

  private def wsa_buffer(bytes)
    wsabuf = LibC::WSABUF.new
    wsabuf.len = bytes.size
    wsabuf.buf = bytes.to_unsafe
    wsabuf
  end

  # :nodoc:
  class CompletionKey
    property fiber : Fiber?
  end

  def self.wait_queued_completions(timeout, &)
    overlapped_entries = uninitialized LibC::OVERLAPPED_ENTRY[1]

    if timeout > UInt64::MAX
      timeout = LibC::INFINITE
    else
      timeout = timeout.to_u64
    end
    result = LibC.GetQueuedCompletionStatusEx(Crystal::Scheduler.event_loop.iocp, overlapped_entries, overlapped_entries.size, out removed, timeout, false)
    if result == 0
      error = WinError.value
      if timeout && error.wait_timeout?
        return true
      else
        raise IO::Error.from_os_error("GetQueuedCompletionStatusEx", error)
      end
    end

    if removed == 0
      raise IO::Error.new("GetQueuedCompletionStatusEx returned 0")
    end

    removed.times do |i|
      entry = overlapped_entries[i]

      # at the moment only `::Process#wait` uses a non-nil completion key; all
      # I/O operations, including socket ones, do not set this field
      case completion_key = Pointer(Void).new(entry.lpCompletionKey).as(CompletionKey?)
      when Nil
        OverlappedOperation.schedule(entry.lpOverlapped) { |fiber| yield fiber }
      else
        case entry.dwNumberOfBytesTransferred
        when LibC::JOB_OBJECT_MSG_EXIT_PROCESS, LibC::JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS
          if fiber = completion_key.fiber
            # this ensures the `::Process` doesn't keep an indirect reference to
            # `::Thread.current`, as that leads to a finalization cycle
            completion_key.fiber = nil

            yield fiber
          else
            # the `Process` exits before a call to `#wait`; do nothing
          end
        end
      end
    end

    false
  end

  class OverlappedOperation
    enum State
      INITIALIZED
      STARTED
      DONE
      CANCELLED
    end

    @overlapped = LibC::OVERLAPPED.new
    @fiber : Fiber? = nil
    @state : State = :initialized
    property next : OverlappedOperation?
    property previous : OverlappedOperation?
    @@canceled = Thread::LinkedList(OverlappedOperation).new
    property? synchronous = false

    def self.run(handle, &)
      operation = OverlappedOperation.new
      begin
        yield operation
      ensure
        operation.done(handle)
      end
    end

    def self.schedule(overlapped : LibC::OVERLAPPED*, &)
      start = overlapped.as(Pointer(UInt8)) - offsetof(OverlappedOperation, @overlapped)
      operation = Box(OverlappedOperation).unbox(start.as(Pointer(Void)))
      operation.schedule { |fiber| yield fiber }
    end

    def start
      raise Exception.new("Invalid state #{@state}") unless @state.initialized?
      @fiber = Fiber.current
      @state = State::STARTED
      pointerof(@overlapped)
    end

    def result(handle, &)
      raise Exception.new("Invalid state #{@state}") unless @state.done? || @state.started?
      result = LibC.GetOverlappedResult(handle, pointerof(@overlapped), out bytes, 0)
      if result.zero?
        error = WinError.value
        yield error

        raise IO::Error.from_os_error("GetOverlappedResult", error)
      end

      bytes
    end

    def wsa_result(socket, &)
      raise Exception.new("Invalid state #{@state}") unless @state.done? || @state.started?
      flags = 0_u32
      result = LibC.WSAGetOverlappedResult(socket, pointerof(@overlapped), out bytes, false, pointerof(flags))
      if result.zero?
        error = WinError.wsa_value
        yield error

        raise IO::Error.from_os_error("WSAGetOverlappedResult", error)
      end

      bytes
    end

    protected def schedule(&)
      case @state
      when .started?
        yield @fiber.not_nil!
        @state = :done
      when .cancelled?
        @@canceled.delete(self)
      else
        raise Exception.new("Invalid state #{@state}")
      end
    end

    protected def done(handle)
      case @state
      when .started?
        handle = LibC::HANDLE.new(handle) if handle.is_a?(LibC::SOCKET)

        # Microsoft documentation:
        # The application must not free or reuse the OVERLAPPED structure
        # associated with the canceled I/O operations until they have completed
        # (this does not apply to asynchronous operations that finished
        # synchronously, as nothing would be queued to the IOCP)
        if !synchronous? && LibC.CancelIoEx(handle, pointerof(@overlapped)) != 0
          @state = :cancelled
          @@canceled.push(self) # to increase lifetime
        end
      end
    end
  end

  # Returns `false` if the operation timed out.
  def schedule_overlapped(timeout : Time::Span?, line = __LINE__) : Bool
    if timeout
      timeout_event = Crystal::Iocp::Event.new(Fiber.current)
      timeout_event.add(timeout)
    else
      timeout_event = Crystal::Iocp::Event.new(Fiber.current, Time::Span::MAX)
    end
    Crystal::Scheduler.event_loop.enqueue(timeout_event)

    Crystal::Scheduler.reschedule

    Crystal::Scheduler.event_loop.dequeue(timeout_event)
  end

  def overlapped_operation(handle, method, timeout, *, writing = false, &)
    OverlappedOperation.run(handle) do |operation|
      result, value = yield operation.start

      if result == 0
        case error = WinError.value
        when .error_handle_eof?
          return 0_u32
        when .error_broken_pipe?
          return 0_u32
        when .error_io_pending?
          # the operation is running asynchronously; do nothing
        when .error_access_denied?
          raise IO::Error.new "File not open for #{writing ? "writing" : "reading"}", target: self
        else
          raise IO::Error.from_os_error(method, error, target: self)
        end
      else
        operation.synchronous = true
        return value
      end

      schedule_overlapped(timeout)

      operation.result(handle) do |error|
        case error
        when .error_io_incomplete?
          raise IO::TimeoutError.new("#{method} timed out")
        when .error_handle_eof?
          return 0_u32
        when .error_broken_pipe?
          # TODO: this is needed for `Process.run`, can we do without it?
          return 0_u32
        end
      end
    end
  end

  def wsa_overlapped_operation(socket, method, timeout, connreset_is_error = true, &)
    OverlappedOperation.run(socket) do |operation|
      result, value = yield operation.start

      if result == LibC::SOCKET_ERROR
        case error = WinError.wsa_value
        when .wsa_io_pending?
          # the operation is running asynchronously; do nothing
        else
          raise IO::Error.from_os_error(method, error, target: self)
        end
      else
        operation.synchronous = true
        return value
      end

      schedule_overlapped(timeout)

      operation.wsa_result(socket) do |error|
        case error
        when .wsa_io_incomplete?
          raise IO::TimeoutError.new("#{method} timed out")
        when .wsaeconnreset?
          return 0_u32 unless connreset_is_error
        end
      end
    end
  end
end

class Crystal::Iocp::Event
  include Crystal::EventLoop::Event

  getter fiber
  getter wake_at
  getter? timeout

  def initialize(@fiber : Fiber, @wake_at = Time.monotonic, *, @timeout = false)
  end

  # Frees the event
  def free : Nil
    Crystal::Scheduler.event_loop.dequeue(self)
  end

  def delete
    free
  end

  def add(timeout : Time::Span?) : Nil
    @wake_at = timeout ? Time.monotonic + timeout : Time.monotonic
    Crystal::Scheduler.event_loop.enqueue(self)
  end
end
