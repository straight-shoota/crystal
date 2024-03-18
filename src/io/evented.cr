{% skip_file if flag?(:win32) %}

require "crystal/thread_local_value"
require "crystal/system/event_loop/libevent"

module IO::Evented
  # :nodoc:
  property read_timed_out = false
  # :nodoc:
  property write_timed_out = false

  @readers = Crystal::ThreadLocalValue(Deque(Fiber)).new
  @writers = Crystal::ThreadLocalValue(Deque(Fiber)).new

  @read_event = Crystal::ThreadLocalValue(Crystal::EventLoop::Event).new
  @write_event = Crystal::ThreadLocalValue(Crystal::EventLoop::Event).new

  @event_loop : Crystal::ThreadLocalValue(Crystal::System::EventLoop::LibEvent) = Crystal::ThreadLocalValue(Crystal::System::EventLoop::LibEvent).new

  def event_loop
    @event_loop.get { Crystal::System::EventLoop::LibEvent.new(Crystal::Scheduler.event_loop) }
  end

  # :nodoc:
  def resume_read(timed_out = false) : Nil
    @read_timed_out = timed_out

    if reader = @readers.get?.try &.shift?
      Crystal::Scheduler.enqueue reader
    end
  end

  # :nodoc:
  def resume_write(timed_out = false) : Nil
    @write_timed_out = timed_out

    if writer = @writers.get?.try &.shift?
      Crystal::Scheduler.enqueue writer
    end
  end
end
