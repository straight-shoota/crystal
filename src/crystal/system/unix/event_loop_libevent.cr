require "./event_libevent"

# :nodoc:
class Crystal::LibEvent::EventLoop < Crystal::EventLoop
  private getter(event_base) { Crystal::LibEvent::Event::Base.new }

  {% unless flag?(:preview_mt) %}
    # Reinitializes the event loop after a fork.
    def after_fork : Nil
      event_base.reinit
    end
  {% end %}

  # Runs the event loop.
  def run_once : Nil
    event_base.run_once
  end

  # Create a new resume event for a fiber.
  def create_resume_event(fiber : Fiber) : Crystal::EventLoop::Event
    event_base.new_event(-1, LibEvent2::EventFlags::None, fiber) do |s, flags, data|
      Crystal::Scheduler.enqueue data.as(Fiber)
    end
  end

  # Creates a timeout_event.
  def create_timeout_event(fiber) : Crystal::EventLoop::Event
    event_base.new_event(-1, LibEvent2::EventFlags::None, fiber) do |s, flags, data|
      f = data.as(Fiber)
      if (select_action = f.timeout_select_action)
        f.timeout_select_action = nil
        select_action.time_expired(f)
      else
        Crystal::Scheduler.enqueue f
      end
    end
  end

  # Creates a write event for a file descriptor.
  def create_fd_write_event(io : IO::Evented, edge_triggered : Bool = false) : Crystal::EventLoop::Event
    flags = LibEvent2::EventFlags::Write
    flags |= LibEvent2::EventFlags::Persist | LibEvent2::EventFlags::ET if edge_triggered

    event_base.new_event(io.fd, flags, io) do |s, flags, data|
      io_ref = data.as(typeof(io))
      if flags.includes?(LibEvent2::EventFlags::Write)
        io_ref.resume_write
      elsif flags.includes?(LibEvent2::EventFlags::Timeout)
        io_ref.resume_write(timed_out: true)
      end
    end
  end

  # Creates a read event for a file descriptor.
  def create_fd_read_event(io : IO::Evented, edge_triggered : Bool = false) : Crystal::EventLoop::Event
    flags = LibEvent2::EventFlags::Read
    flags |= LibEvent2::EventFlags::Persist | LibEvent2::EventFlags::ET if edge_triggered

    event_base.new_event(io.fd, flags, io) do |s, flags, data|
      io_ref = data.as(typeof(io))
      if flags.includes?(LibEvent2::EventFlags::Read)
        io_ref.resume_read
      elsif flags.includes?(LibEvent2::EventFlags::Timeout)
        io_ref.resume_read(timed_out: true)
      end
    end
  end

  def read(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32
    loop do
      bytes_read = LibC.read(file.fd, slice, slice.size).to_i32
      if bytes_read != -1
        # `to_i32` is acceptable because `Slice#size` is an Int32
        return bytes_read.to_i32
      end

      if Errno.value == Errno::EAGAIN
        wait_readable(file)
      elsif Errno.value == Errno::EBADF
        raise IO::Error.new "File not open for reading", target: file
      else
        raise IO::Error.from_errno("Error reading file", target: file)
      end
    end
  ensure
    resume_pending_readers(file)
  end

  def read(socket : ::Socket, slice : Bytes) : Int32
    loop do
      bytes_read = LibC.recv(socket.fd, slice, slice.size, 0).to_i32
      if bytes_read != -1
        # `to_i32` is acceptable because `Slice#size` is an Int32
        return bytes_read.to_i32
      end

      if Errno.value == Errno::EAGAIN
        wait_readable(socket)
      else
        raise IO::Error.from_errno("Error reading socket", target: socket)
      end
    end
  ensure
    resume_pending_readers(socket)
  end

  def write(file : Crystal::System::FileDescriptor, slice : Bytes) : Nil
    return if slice.empty?

    loop do
      # TODO: Investigate why the .to_i64 is needed as a workaround for #8230
      bytes_written = LibC.write(file.fd, slice, slice.size).to_i64
      if bytes_written != -1
        slice += bytes_written
        return if slice.size == 0
      else
        if Errno.value == Errno::EAGAIN
          wait_writable(file)
        elsif Errno.value == Errno::EBADF
          raise IO::Error.new "File not open for writing", target: file
        else
          raise IO::Error.from_errno("Error writing file", target: file)
        end
      end
    end
  ensure
    resume_pending_writers(file)
  end

  def write(socket : ::Socket, slice : Bytes) : Nil
    return if slice.empty?

    loop do
      # TODO: Investigate why the .to_i64 is needed as a workaround for #8230
      bytes_written = LibC.send(socket.fd, slice, slice.size, 0).to_i64
      if bytes_written != -1
        slice += bytes_written
        return if slice.size == 0
      else
        if Errno.value == Errno::EAGAIN
          wait_writable(socket)
        else
          raise IO::Error.from_errno("Error writing to socket", target: socket)
        end
      end
    end
  ensure
    resume_pending_writers(socket)
  end

  def accept(socket : ::Socket) : Socket::Handle?
    loop do
      client_fd = LibC.accept(socket.fd, nil, nil)
      if client_fd == -1
        if socket.closed?
          return
        elsif Errno.value == Errno::EAGAIN
          wait_acceptable(socket)
          return if socket.closed?
        else
          raise ::Socket::Error.from_errno("accept")
        end
      else
        return client_fd
      end
    end
  end

  private def wait_acceptable(io)
    wait_readable(io, raise_if_closed: false) do
      raise IO::TimeoutError.new("Accept timed out")
    end
  end

  def connect(socket : ::Socket, addr : ::Socket::Addrinfo | ::Socket::Address, timeout : ::Time::Span?, & : IO::Error ->) : Nil
    loop do
      if LibC.connect(socket.fd, addr, addr.size) == 0
        return
      end
      case Errno.value
      when Errno::EISCONN
        return
      when Errno::EINPROGRESS, Errno::EALREADY
        wait_writable(socket, timeout: timeout) do
          return yield IO::TimeoutError.new("connect timed out")
        end
      else
        return yield ::Socket::ConnectError.from_errno("connect")
      end
    end
  end

  def send(socket : ::Socket, slice : Bytes) : Int32
    bytes_written = LibC.send(socket.fd, slice.to_unsafe.as(Void*), slice.size, 0)
    raise ::Socket::Error.from_errno("Error sending datagram") if bytes_written == -1
    # `to_i32` is acceptable because `Slice#size` is an Int32
    bytes_written.to_i32
  ensure
    resume_pending_writers(socket)
  end

  def send_to(socket : ::Socket, bytes : Bytes, addr : ::Socket::Address) : Int32
    bytes_sent = LibC.sendto(socket.fd, bytes.to_unsafe.as(Void*), bytes.size, 0, addr, addr.size)
    raise ::Socket::Error.from_errno("Error sending datagram to #{addr}") if bytes_sent == -1
    # to_i32 is fine because string/slice sizes are an Int32
    bytes_sent.to_i32
  end

  def receive_from(socket : ::Socket, slice : Bytes) : Tuple(Int32, ::Socket::Address)
    sockaddr = Pointer(LibC::SockaddrStorage).malloc.as(LibC::Sockaddr*)
    # initialize sockaddr with the initialized family of the socket
    copy = sockaddr.value
    copy.sa_family = socket.family
    sockaddr.value = copy

    addrlen = LibC::SocklenT.new(sizeof(LibC::SockaddrStorage))

    begin
      loop do
        bytes_read = LibC.recvfrom(socket.fd, slice, slice.size, 0, sockaddr, pointerof(addrlen)).to_i32
        if bytes_read != -1
          # `to_i32` is acceptable because `Slice#size` is an Int32
          return {bytes_read.to_i32, Socket::Address.from(sockaddr, addrlen)}
        end

        if Errno.value == Errno::EAGAIN
          wait_readable(socket)
        else
          raise IO::Error.from_errno("Error receiving datagram", target: socket)
        end
      end
    ensure
      resume_pending_readers(socket)
    end
  end

  def receive(socket : ::Socket, slice : Bytes) : Int32
    receive_from(socket, slice)[0]
  end

  # :nodoc:
  def wait_readable(io, timeout = io.@read_timeout) : Nil
    wait_readable(io, timeout: timeout) { raise IO::TimeoutError.new("Read timed out") }
  end

  # :nodoc:
  def wait_readable(io, timeout = io.@read_timeout, *, raise_if_closed = true, &) : Nil
    readers = io.@readers.get { Deque(::Fiber).new }
    readers << ::Fiber.current
    add_read_event(io, timeout)
    Crystal::Scheduler.reschedule

    if io.@read_timed_out
      io.read_timed_out = false
      yield
    end

    io.check_open if raise_if_closed
  end

  private def add_read_event(io, timeout = io.@read_timeout) : Nil
    event = io.@read_event.get { create_fd_read_event(io) }
    event.add timeout
  end

  # :nodoc:
  def wait_writable(io, timeout = io.@write_timeout) : Nil
    wait_writable(io, timeout: timeout) { raise IO::TimeoutError.new("Write timed out") }
  end

  # :nodoc:
  def wait_writable(io, timeout = io.@write_timeout, &) : Nil
    writers = io.@writers.get { Deque(::Fiber).new }
    writers << ::Fiber.current
    add_write_event(io, timeout)
    Crystal::Scheduler.reschedule

    if io.@write_timed_out
      io.write_timed_out = false
      yield
    end

    io.check_open
  end

  private def add_write_event(io, timeout = io.@write_timeout) : Nil
    event = io.@write_event.get { create_fd_write_event(io) }
    event.add timeout
  end

  private def resume_pending_readers(io)
    if (readers = io.@readers.get?) && !readers.empty?
      add_read_event(io)
    end
  end

  private def resume_pending_writers(io)
    if (writers = io.@writers.get?) && !writers.empty?
      add_write_event(io)
    end
  end

  def close(io) : Nil
    io.@read_event.consume_each &.free

    io.@write_event.consume_each &.free

    io.@readers.consume_each do |readers|
      Crystal::Scheduler.enqueue readers
    end

    io.@writers.consume_each do |writers|
      Crystal::Scheduler.enqueue writers
    end
  end
end
