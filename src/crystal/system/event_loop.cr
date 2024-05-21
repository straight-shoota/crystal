abstract class Crystal::EventLoop
  # Creates an event loop instance
  # def self.create

  @[AlwaysInline]
  def self.current : self
    Crystal::Scheduler.event_loop
  end

  # Runs the loop.
  #
  # Returns immediately if events are activable. Set `blocking` to false to
  # return immediately if there are no activable events; set it to true to wait
  # for activable events, which will block the current thread until then.
  #
  # Returns `true` on normal returns (e.g. has activated events, has pending
  # events but blocking was false) and `false` when there are no registered
  # events.
  abstract def run(blocking : Bool) : Bool

  # Tells a blocking run loop to no longer wait for events to activate. It may
  # for example enqueue a NOOP event with an immediate (or past) timeout. Having
  # activated an event, the loop shall return, allowing the blocked thread to
  # continue.
  #
  # Should be a NOOP when the loop isn't running or is running in a nonblocking
  # mode.
  #
  # NOTE: we assume that multiple threads won't run the event loop at the same
  #       time in parallel, but this assumption may change in the future!
  abstract def interrupt : Nil

  # Reads at least one byte from the file descriptor into *slice* and continues
  # fiber when the read is complete.
  # Returns the number of bytes read.
  abstract def read(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32

  # Reads at least one byte from the socket into *slice* and continues fiber
  # when the read is complete.
  # Returns the number of bytes read.
  abstract def read(socket : ::Socket, slice : Bytes) : Int32

  # Writes at least one byte from *slice* to the file descriptor and continues
  # fiber when the write is complete.
  # Returns the number of bytes written.
  abstract def write(file : Crystal::System::FileDescriptor, slice : Bytes) : Int32

  # Writes at least one byte from *slice* to the socket and continues fiber
  # when the write is complete.
  # Returns the number of bytes written.
  abstract def write(file : ::Socket, slice : Bytes) : Int32

  # Accepts an incoming TCP connection on the socket and continues fiber when a
  # connection is available.
  # Returns a handle to the socket for the new connection.
  # abstract def accept(socket : ::Socket) : ::Socket::Handle?

  # Opens a connection on *socket* to the target *address* and continues fiber
  # when the connection has been established.
  # Returns `IO::Error` but does not raise.
  abstract def connect(socket : ::Socket, address : ::Socket::Addrinfo | ::Socket::Address, timeout : ::Time::Span?) : IO::Error?

  # Writes at least one byte from *slice* to the socket and continues fiber when
  # the write is complete.
  # Returns the number of bytes written.
  abstract def send(socket : ::Socket, slice : Bytes) : Int32

  # Writes at least one byte from *slice* to the socket with a target *address* (UDP)
  # and continues fiber when the write is complete.
  # Returns the number of bytes written.
  abstract def send_to(socket : ::Socket, slice : Bytes, address : ::Socket::Address) : Int32

  # Receives on the socket into *slice*  and continues fiber when the package is
  # completed
  # Returns the number of bytes received.
  abstract def receive(socket : ::Socket, slice : Bytes) : Int32

  # Receives on the socket into *slice*  and continues fiber when the package is
  # completed.
  # Returns a tuple containing the number of bytes received and the source address
  # of the packet (UDP).
  # abstract def receive_from(socket : ::Socket, slice : Bytes) : Tuple(Int32, ::Socket::Address)

  # Closes the *resource*.
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
