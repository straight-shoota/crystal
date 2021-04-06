require "crystal/system/print_error"

module Crystal::EventLoop
  @@queue = Deque(Event).new

  # Runs the event loop.
  def self.run_once : Nil
    next_event = @@queue.min_by { |e| e.wake_at }

    if next_event
      sleep_time = next_event.wake_at - Time.monotonic

      if sleep_time > Time::Span.zero
        LibC.Sleep(sleep_time.milliseconds)
      end

      dequeue next_event

      next_event.activate
    else
      Crystal::System.print_error "Warning: No runnables in scheduler. Exiting program.\n"
      ::exit
    end
  end

  # Reinitializes the event loop after a fork.
  def self.after_fork : Nil
  end

  def self.enqueue(event : Event)
    unless @@queue.includes?(event)
      @@queue << event
    end
  end

  def self.dequeue(event : Event)
    @@queue.delete(event)
  end

  # Create a new resume event for a fiber.
  def self.create_resume_event(fiber : Fiber) : Crystal::Event
    Crystal::Event.new(fiber)
  end

  # Create a new resume event for a fiber.
  def self.create_timeout_event(fiber : Fiber) : Crystal::Event
    Crystal::Event.new(fiber, timeout_event: true)
  end

  # Creates a write event for a file descriptor.
  def self.create_fd_write_event(io : IO::Evented, edge_triggered : Bool = false) : Crystal::Event
    Crystal::Event.new(Fiber.current)
  end

  # Creates a read event for a file descriptor.
  def self.create_fd_read_event(io : IO::Evented, edge_triggered : Bool = false) : Crystal::Event
    Crystal::Event.new(Fiber.current)
  end
end

struct Crystal::Event
  getter wake_at

  def initialize(@fiber : Fiber, @timeout_event = false)
    @wake_at = Time.monotonic
  end

  # Frees the event
  def free : Nil
    delete
  end

  def delete
    Crystal::EventLoop.dequeue(self)
  end

  def add(time_span : Time::Span) : Nil
    @wake_at = Time.monotonic + time_span
    Crystal::EventLoop.enqueue(self)
  end

  def activate
    if @timeout_event && (select_action = @fiber.timeout_select_action)
      @fiber.timeout_select_action = nil
      select_action.time_expired(@fiber)
    else
      Crystal::Scheduler.enqueue @fiber
    end
  end
end
