# :nodoc:
class Crystal::Wasi::EventLoop < Crystal::EventLoop
  # Runs the event loop.
  def run_once : Nil
    raise NotImplementedError.new("Crystal::Wasi::EventLoop.run_once")
  end

  # Reads from the file descriptor into *slice* and continues fiber when the read
  # is completed.
  # Returns the number of bytes read.
  def read(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#read")
  end

  # Reads from the socket into *slice* and continues fiber when the read
  # is completed.
  # Returns the number of bytes read.
  def read(socket : ::Socket, slice : Bytes) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#read")
  end

  # Writes *slice* to the file descriptor and continues fiber when the write is
  # completed.
  # Returns the number of bytes written.
  def write(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#write")
  end

  # Writes *slice* to the socket and continues fiber when the write is
  # completed.
  # Returns the number of bytes written.
  def write(file : ::Socket, slice : Bytes) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#write")
  end

  # Accepts a new connection on the socket and continues fiber when a connection
  # is available.
  # Returns a handle to the new socket.
  def accept(socket : ::Socket) : ::Socket::Handle?
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#accept")
  end

  # Connects socket to the given *addr* and continues fiber when the connection
  # has been established.
  def connect(socket : ::Socket, addr : ::Socket::Addrinfo | ::Socket::Address, timeout : ::Time::Span?, & : IO::Error ->) : Nil
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#connect")
  end

  # Sends *slice* to the socket continues fiber when the write is
  # completed.
  def send(socket : ::Socket, slice : Bytes) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#send")
  end

  # Sends *slice* to the socket continues fiber when the write is
  # completed.
  def send_to(socket : ::Socket, slice : Bytes, addr : ::Socket::Address) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#send_to")
  end

  # Receives on the socket into *slice*  and continues fiber when the package is
  # completed.
  # Returns the number of bytes received.
  def receive(socket : ::Socket, slice : Bytes) : Int32
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#receive")
  end

  # Receives on the socket into *slice*  and continues fiber when the package is
  # completed.
  # Returns a tuple containing the number of bytes received and the remote address.
  def receive_from(socket : ::Socket, slice : Bytes) : Tuple(Int32, ::Socket::Address)
    raise NotImplementedError.new("Crystal::Wasi::EventLoop#receive_from(socket : ::Socket, slice : Bytes) : Tuple")
  end

  # Closes the evented resource.
  def close(resource) : Nil
  end
end

struct Crystal::Wasi::Event
  include Crystal::EventLoop::Event

  def add(timeout : Time::Span?) : Nil
  end

  def free : Nil
  end

  def delete
  end
end
