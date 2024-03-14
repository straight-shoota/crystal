class Crystal::System::EventLoop::LibEvent
  def initialize(@libevent : Crystal::LibEvent::EventLoop)
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

  def write(file : Crystal::System::FileDescriptor, slice : Bytes)
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

  def write(socket : ::Socket, slice : Bytes)
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

  def accept(socket : ::Socket)
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

  def connect(socket : ::Socket, addr, timeout, &)
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

  def receive(socket : ::Socket, slice : Bytes)
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
          return {bytes_read.to_i32, sockaddr, addrlen}
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
    event = io.@read_event.get { @libevent.create_fd_read_event(io) }
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
    event = io.@write_event.get { @libevent.create_fd_write_event(io) }
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

  def cleanup(io) : Nil
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
