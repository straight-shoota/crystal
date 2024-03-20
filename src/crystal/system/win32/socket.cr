require "c/mswsock"
require "c/ioapiset"

module Crystal::System::Socket
  alias Handle = LibC::SOCKET

  # Initialize WSA
  def self.initialize_wsa
    # version 2.2
    wsa_version = 0x202
    err = LibC.WSAStartup(wsa_version, out wsadata)
    unless err.zero?
      raise IO::Error.from_os_error("WSAStartup", WinError.new(err.to_u32))
    end

    if wsadata.wVersion != wsa_version
      raise IO::Error.new("Unsuitable version of Winsock.dll: 0x#{wsadata.wVersion.to_s(16)}")
    end
  end

  def self.load_extension_function(socket, guid, proc_type)
    function_pointer = uninitialized Pointer(Void)
    result = LibC.WSAIoctl(
      socket,
      LibC::SIO_GET_EXTENSION_FUNCTION_POINTER,
      pointerof(guid),
      sizeof(LibC::GUID),
      pointerof(function_pointer),
      sizeof(Pointer(Void)),
      out bytes,
      nil,
      nil
    )
    if result == LibC::SOCKET_ERROR
      raise ::Socket::Error.from_wsa_error("WSAIoctl")
    end
    proc_type.new(function_pointer, Pointer(Void).null)
  end

  class_getter connect_ex
  class_getter accept_ex
  @@connect_ex = uninitialized LibC::ConnectEx
  @@accept_ex = uninitialized LibC::AcceptEx

  # Some overlapped socket functions are not part of the Winsock specification.
  # The implementation is provider-specific and needs to be queried at runtime
  # with WSAIoctl.
  # Crystal's socket implementation only uses Microsoft's default provider,
  # so the same function can be shared across all sockets because they all use
  # the same provider.
  #
  # https://stackoverflow.com/questions/37355397/why-is-the-wsarecvmsg-function-implemented-as-a-function-pointer-and-can-this-po/37356935#37356935
  def self.initialize_extension_functions
    initialize_wsa

    # Create dummy socket for WSAIoctl
    socket = LibC.socket(LibC::AF_INET, LibC::SOCK_STREAM, 0)
    if socket == LibC::INVALID_SOCKET
      raise ::Socket::Error.from_wsa_error("socket")
    end

    @@connect_ex = load_extension_function(socket, LibC::WSAID_CONNECTEX, LibC::ConnectEx)
    @@accept_ex = load_extension_function(socket, LibC::WSAID_ACCEPTEX, LibC::AcceptEx)

    result = LibC.closesocket(socket)
    unless result.zero?
      raise ::Socket::Error.from_wsa_error("closesocket")
    end
  end

  initialize_extension_functions

  # :nodoc:
  def create_handle(family, type, protocol, blocking) : Handle
    socket = LibC.WSASocketW(family, type, protocol, nil, 0, LibC::WSA_FLAG_OVERLAPPED)
    if socket == LibC::INVALID_SOCKET
      raise ::Socket::Error.from_wsa_error("WSASocketW")
    end

    Crystal::Scheduler.event_loop.create_completion_port LibC::HANDLE.new(socket)

    socket
  end

  # :nodoc:
  def initialize_handle(handle)
    unless @family.unix?
      system_getsockopt(handle, LibC::SO_REUSEADDR, 0) do |value|
        if value == 0
          system_setsockopt(handle, LibC::SO_EXCLUSIVEADDRUSE, 1)
        end
      end
    end
  end

  private def system_bind(addr, addrstr, &)
    unless LibC.bind(fd, addr, addr.size) == 0
      yield ::Socket::BindError.from_wsa_error("Could not bind to '#{addrstr}'")
    end
  end

  private def system_listen(backlog, &)
    unless LibC.listen(fd, backlog) == 0
      yield ::Socket::Error.from_wsa_error("Listen failed")
    end
  end

  private def system_close_read
    if LibC.shutdown(fd, LibC::SH_RECEIVE) != 0
      raise ::Socket::Error.from_wsa_error("shutdown read")
    end
  end

  private def system_close_write
    if LibC.shutdown(fd, LibC::SH_SEND) != 0
      raise ::Socket::Error.from_wsa_error("shutdown write")
    end
  end

  private def system_send_buffer_size : Int
    getsockopt LibC::SO_SNDBUF, 0
  end

  private def system_send_buffer_size=(val : Int)
    setsockopt LibC::SO_SNDBUF, val
  end

  private def system_recv_buffer_size : Int
    getsockopt LibC::SO_RCVBUF, 0
  end

  private def system_recv_buffer_size=(val : Int)
    setsockopt LibC::SO_RCVBUF, val
  end

  # SO_REUSEADDR, as used in posix, is always assumed on windows
  # the SO_REUSEADDR flag on windows is the equivalent of SO_REUSEPORT on linux
  # https://learn.microsoft.com/en-us/windows/win32/winsock/using-so-reuseaddr-and-so-exclusiveaddruse#application-strategies
  private def system_reuse_address? : Bool
    true
  end

  private def system_reuse_address=(val : Bool)
    raise NotImplementedError.new("Crystal::System::Socket#system_reuse_address=") unless val
  end

  private def system_reuse_port?
    getsockopt_bool LibC::SO_REUSEADDR
  end

  private def system_reuse_port=(val : Bool)
    if val
      setsockopt_bool LibC::SO_EXCLUSIVEADDRUSE, false
      setsockopt_bool LibC::SO_REUSEADDR, true
    else
      setsockopt_bool LibC::SO_REUSEADDR, false
      setsockopt_bool LibC::SO_EXCLUSIVEADDRUSE, true
    end
  end

  private def system_broadcast? : Bool
    getsockopt_bool LibC::SO_BROADCAST
  end

  private def system_broadcast=(val : Bool)
    setsockopt_bool LibC::SO_BROADCAST, val
  end

  private def system_keepalive? : Bool
    getsockopt_bool LibC::SO_KEEPALIVE
  end

  private def system_keepalive=(val : Bool)
    setsockopt_bool LibC::SO_KEEPALIVE, val
  end

  private def system_linger
    v = LibC::Linger.new
    ret = getsockopt LibC::SO_LINGER, v
    ret.l_onoff == 0 ? nil : ret.l_linger
  end

  private def system_linger=(val)
    v = LibC::Linger.new
    case val
    when Int
      v.l_onoff = 1
      v.l_linger = val
    when nil
      v.l_onoff = 0
    end

    setsockopt LibC::SO_LINGER, v
    val
  end

  private def system_getsockopt(handle, optname, optval, level = LibC::SOL_SOCKET, &)
    optsize = sizeof(typeof(optval))
    ret = LibC.getsockopt(handle, level, optname, pointerof(optval).as(UInt8*), pointerof(optsize))
    yield optval if ret == 0
    ret
  end

  private def system_getsockopt(fd, optname, optval, level = LibC::SOL_SOCKET)
    system_getsockopt(fd, optname, optval, level) { |value| return value }
    raise ::Socket::Error.from_wsa_error("getsockopt #{optname}")
  end

  # :nodoc:
  def system_setsockopt(handle, optname, optval, level = LibC::SOL_SOCKET)
    optsize = sizeof(typeof(optval))

    ret = LibC.setsockopt(handle, level, optname, pointerof(optval).as(UInt8*), optsize)
    raise ::Socket::Error.from_wsa_error("setsockopt #{optname}") if ret == LibC::SOCKET_ERROR
    ret
  end

  @blocking = true

  # WSA does not provide a direct way to query the blocking mode of a file descriptor.
  # The best option seems to be just keeping track in an instance variable.
  # This becomes invalid if the blocking mode was changed directly on the
  # socket handle without going through `Socket#blocking=`.
  private def system_blocking?
    @blocking
  end

  private def system_blocking=(@blocking)
    mode = blocking ? 1_u32 : 0_u32
    ret = LibC.WSAIoctl(fd, LibC::FIONBIO, pointerof(mode), sizeof(UInt32), nil, 0, out bytes_returned, nil, nil)
    raise ::Socket::Error.from_wsa_error("WSAIoctl") unless ret.zero?
  end

  private def system_close_on_exec?
    flags = fcntl(LibC::F_GETFD)
    (flags & LibC::FD_CLOEXEC) == LibC::FD_CLOEXEC
  end

  private def system_close_on_exec=(arg : Bool)
    fcntl(LibC::F_SETFD, arg ? LibC::FD_CLOEXEC : 0)
    arg
  end

  def self.fcntl(fd, cmd, arg = 0)
    raise NotImplementedError.new "Crystal::System::Socket.fcntl"
  end

  private def system_tty?
    false
  end

  def system_close
    handle = @volatile_fd.swap(LibC::INVALID_SOCKET)

    ret = LibC.closesocket(handle)

    if ret != 0
      case Errno.value
      when Errno::EINTR, Errno::EINPROGRESS
        # ignore
      else
        return ::Socket::Error.from_wsa_error("Error closing socket")
      end
    end
  end

  private def system_local_address
    sockaddr6 = uninitialized LibC::SockaddrIn6
    sockaddr = pointerof(sockaddr6).as(LibC::Sockaddr*)
    addrlen = sizeof(LibC::SockaddrIn6)

    ret = LibC.getsockname(fd, sockaddr, pointerof(addrlen))
    if ret == LibC::SOCKET_ERROR
      raise ::Socket::Error.from_wsa_error("getsockname")
    end

    ::Socket::IPAddress.from(sockaddr, addrlen)
  end

  private def system_remote_address
    sockaddr6 = uninitialized LibC::SockaddrIn6
    sockaddr = pointerof(sockaddr6).as(LibC::Sockaddr*)
    addrlen = sizeof(LibC::SockaddrIn6)

    ret = LibC.getpeername(fd, sockaddr, pointerof(addrlen))
    if ret == LibC::SOCKET_ERROR
      raise ::Socket::Error.from_wsa_error("getpeername")
    end

    ::Socket::IPAddress.from(sockaddr, addrlen)
  end

  private def system_tcp_keepalive_idle
    getsockopt LibC::TCP_KEEPIDLE, 0, level: ::Socket::Protocol::TCP
  end

  private def system_tcp_keepalive_idle=(val : Int)
    setsockopt LibC::TCP_KEEPIDLE, val, level: ::Socket::Protocol::TCP
    val
  end

  # The amount of time in seconds between keepalive probes.
  private def system_tcp_keepalive_interval
    getsockopt LibC::TCP_KEEPINTVL, 0, level: ::Socket::Protocol::TCP
  end

  private def system_tcp_keepalive_interval=(val : Int)
    setsockopt LibC::TCP_KEEPINTVL, val, level: ::Socket::Protocol::TCP
    val
  end

  # The number of probes sent, without response before dropping the connection.
  private def system_tcp_keepalive_count
    getsockopt LibC::TCP_KEEPCNT, 0, level: ::Socket::Protocol::TCP
  end

  private def system_tcp_keepalive_count=(val : Int)
    setsockopt LibC::TCP_KEEPCNT, val, level: ::Socket::Protocol::TCP
    val
  end
end
