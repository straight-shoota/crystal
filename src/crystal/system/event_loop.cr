abstract class Crystal::EventLoop
  # Creates an event loop instance
  def self.create
    {% if flag?(:wasi) %}
      Crystal::Wasi::EventLoop.new
    {% elsif flag?(:unix) %}
      Crystal::LibEvent::EventLoop.new
    {% elsif flag?(:win32) %}
      Crystal::Iocp::EventLoop.new
    {% else %}
      {% raise "Event loop not supported" %}
    {% end %}
  end

  # Reads from the file descriptor into *slice* and continues fiber when the read
  # is completed.
  # Returns the number of bytes read.
  abstract def read(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32

  # Reads from the socket into *slice* and continues fiber when the read
  # is completed.
  # Returns the number of bytes read.
  abstract def read(socket : ::Socket, slice : Bytes) : Int32

  # Writes *slice* to the file descriptor and continues fiber when the write is
  # completed.
  abstract def write(file : Crystal::System::FileDescriptor, slice : Bytes) : Nil

  # Writes *slice* to the socket and continues fiber when the write is
  # completed.
  abstract def write(file : ::Socket, slice : Bytes) : Nil

  # Accepts a new connection on the socket and continues fiber when a connection
  # is available.
  # Returns a handle to the new socket.
  # abstract def accept(socket : ::Socket) : ::Socket::Handle?

  # Connects socket to the given *addr* and continues fiber when the connection
  # has been established.
  abstract def connect(socket : ::Socket, addr : ::Socket::Addrinfo | ::Socket::Address, timeout : ::Time::Span?, & : IO::Error ->) : Nil

  # Sends *slice* to the socket continues fiber when the write is
  # completed.
  abstract def send(socket : ::Socket, slice : Bytes) : Int32

  # Sends *slice* to the socket continues fiber when the write is
  # completed.
  abstract def send_to(socket : ::Socket, slice : Bytes, addr : ::Socket::Address) : Int32

  # Receives on the socket into *slice*  and continues fiber when the package is
  # completed.
  # Returns the number of bytes received.
  abstract def receive(socket : ::Socket, slice : Bytes) : Int32

  # Receives on the socket into *slice*  and continues fiber when the package is
  # completed.
  # Returns a tuple containing the number of bytes received and the remote address.
  # abstract def receive_from(socket : ::Socket, slice : Bytes) : Tuple(Int32, ::Socket::Address)

  # Closes the evented resource.
  abstract def close(resource) : Nil

  # TODO: Remove
  module Event
    # Frees the event.
    abstract def free : Nil

    # Adds a new timeout to this event.
    abstract def add(timeout : Time::Span?) : Nil
  end
end

{% if flag?(:wasi) %}
  require "./wasi/event_loop"
{% elsif flag?(:unix) %}
  require "./unix/event_loop_libevent"
{% elsif flag?(:win32) %}
  require "./win32/event_loop_iocp"
{% else %}
  {% raise "Event loop not supported" %}
{% end %}
