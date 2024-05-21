module Crystal::System::Socket
  # Creates a file descriptor / socket handle
  # private def create_handle(family, type, protocol, blocking) : Handle

  # Initializes a file descriptor / socket handle for use with Crystal Socket
  # private def initialize_handle(fd)

  private def system_connect(addr, timeout = nil)
    timeout = timeout.seconds unless timeout.is_a? ::Time::Span | Nil
    event_loop.connect(self, addr, timeout)
  end

  # Tries to bind the socket to a local address.
  # Yields an `Socket::BindError` if the binding failed.
  # private def system_bind(addr, addrstr)

  # private def system_listen(backlog)

  private def system_accept
    event_loop.accept(self)
  end

  private def system_send(bytes)
    event_loop.send(self, bytes)
  end

  private def system_send_to(bytes, addr)
    event_loop.send_to(self, bytes, addr)
  end

  private def system_receive(bytes)
    event_loop.receive_from(self, bytes)
  end

  # private def system_close_read

  # private def system_close_write

  # private def system_send_buffer_size : Int

  # private def system_send_buffer_size=(val : Int)

  # private def system_recv_buffer_size : Int

  # private def system_recv_buffer_size=(val : Int)

  # private def system_reuse_address? : Bool

  # private def system_reuse_address=(val : Bool)

  # private def system_reuse_port? : Bool

  # private def system_reuse_port=(val : Bool)

  # private def system_broadcast? : Bool

  # private def system_broadcast=(val : Bool)

  # private def system_keepalive? : Bool

  # private def system_keepalive=(val : Bool)

  # private def system_linger

  # private def system_linger=(val)

  # private def system_getsockopt(fd, optname, optval, level = LibC::SOL_SOCKET, &)

  # private def system_getsockopt(fd, optname, optval, level = LibC::SOL_SOCKET)

  # private def system_setsockopt(fd, optname, optval, level = LibC::SOL_SOCKET)

  # private def system_blocking?

  # private def system_blocking=(value)

  # private def system_tty?

  # private def system_close_on_exec?

  # private def system_close_on_exec=(arg : Bool)

  # def self.fcntl(fd, cmd, arg = 0)

  # IPSocket:

  # private def system_local_address

  # private def system_remote_address

  # TCPSocket:

  # private def system_tcp_keepalive_idle

  # private def system_tcp_keepalive_idle=(val : Int)

  # private def system_tcp_keepalive_interval

  # private def system_tcp_keepalive_interval=(val : Int)

  # private def system_tcp_keepalive_count

  # private def system_tcp_keepalive_count=(val : Int)

  private def unbuffered_read(slice : Bytes) : Int32
    event_loop.read(self, slice)
  end

  private def unbuffered_write(slice : Bytes) : Nil
    until slice.empty?
      bytes_written = event_loop.write(self, slice)
      slice += bytes_written
    end
  end

  private def event_loop
    Crystal::EventLoop.current
  end
end

{% if flag?(:wasi) %}
  require "./wasi/socket"
{% elsif flag?(:unix) %}
  require "./unix/socket"
{% elsif flag?(:win32) %}
  require "./win32/socket"
{% else %}
  {% raise "No Crystal::System::Socket implementation available" %}
{% end %}
