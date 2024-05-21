# :nodoc:
module Crystal::System::FileDescriptor
  # Enables input echoing if *enable* is true, disables it otherwise.
  # private def system_echo(enable : Bool)

  # For the duration of the block, enables input echoing if *enable* is true,
  # disables it otherwise.
  # private def system_echo(enable : Bool, & : ->)

  # Enables raw mode if *enable* is true, enables cooked mode otherwise.
  # private def system_raw(enable : Bool)

  # For the duration of the block, enables raw mode if *enable* is true, enables
  # cooked mode otherwise.
  # private def system_raw(enable : Bool, & : ->)

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
  require "./wasi/file_descriptor"
{% elsif flag?(:unix) %}
  require "./unix/file_descriptor"
{% elsif flag?(:win32) %}
  require "./win32/file_descriptor"
{% else %}
  {% raise "No Crystal::System::FileDescriptor implementation available" %}
{% end %}
