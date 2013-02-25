require 'monitor'

# Ruby 1.9.1 specific fixes.
if RUBY_VERSION.between?('1.9', '1.9.1')
  require 'god/compat19'
end

module God
  # The TimedEvent class represents an event in the future. This class is used
  # by the drivers to schedule upcoming conditional tests and other scheduled
  # events.
  class TimedEvent
    include Comparable

    # The Time at which this event is due.
    attr_accessor :at

    # Instantiate a new TimedEvent that will be triggered after the specified
    # delay.
    #
    # delay - The optional Numeric number of seconds from now at which to
    #         trigger (default: 0).
    def initialize(delay = 0)
      self.at = Time.now + delay
    end

    # Is the current event due (current time >= event time)?
    #
    # Returns true if the event is due, false if not.
    def due?
      Time.now >= self.at
    end

    # Compare this event to another.
    #
    # other - The other TimedEvent.
    #
    # Returns -1 if this event is before the other, 0 if the two events are
    #   due at the same time, 1 if the other event is later.
    def <=>(other)
      self.at <=> other.at
    end
  end

  # A DriverEvent is a TimedEvent with an associated Task and Condition. This
  # is the primary mechanism for poll conditions to be scheduled.
  class DriverEvent < TimedEvent
    # Initialize a new DriverEvent.
    #
    # delay     - The Numeric delay for this event.
    # task      - The Task associated with this event.
    # condition - The Condition associated with this event.
    def initialize(delay, task, condition)
      super(delay)
      @task = task
      @condition = condition
    end

    # Handle this event by invoking the underlying condition on the associated
    # task.
    #
    # Returns nothing.
    def handle_event
      @task.handle_poll(@condition)
    end
  end

  # A DriverOperation is a TimedEvent that is due as soon as possible. It is
  # used to execute an arbitrary method on the associated Task.
  class DriverOperation < TimedEvent
    # Initialize a new DriverOperation.
    #
    # task - The Task upon which to operate.
    # name - The Symbol name of the method to call.
    # args - The Array of arguments to send to the method.
    def initialize(task, name, args)
      super(0)
      @task = task
      @name = name
      @args = args
    end

    # Handle the operation that was issued asynchronously.
    #
    # Returns nothing.
    def handle_event
      @task.send(@name, *@args)
    end
  end

  # The DriverEventQueue is a simple queue that holds TimedEvent instances in
  # order to maintain the schedule of upcoming events.
  class DriverEventQueue
    # Initialize a DriverEventQueue.
    def initialize
      @shutdown = false
      @events = []
      @monitor = Monitor.new
      @resource = @monitor.new_cond
    end

    # Wake any sleeping threads after setting the sentinel.
    #
    # Returns nothing.
    def shutdown
      @shutdown = true
      @monitor.synchronize do
        @resource.broadcast
      end
    end

    # Wait until the queue has something due, pop it off the queue, and return
    # it.
    #
    # Returns the popped event.
    def pop
      @monitor.synchronize do
        if @events.empty?
          raise ThreadError, "queue empty" if @shutdown
          @resource.wait
        else
          delay = @events.first.at - Time.now
          @resource.wait(delay) if delay > 0
        end

        @events.shift
      end
    end

    # Add an event to the queue, wake any waiters if what we added needs to
    # happen sooner than the next pending event.
    #
    # Returns nothing.
    def push(event)
      @monitor.synchronize do
        @events << event
        @events.sort!

        # If we've sorted the events and found the one we're adding is at
        # the front, it will likely need to run before the next due date.
        @resource.signal if @events.first == event
      end
    end

    # Returns true if the queue is empty, false if not.
    def empty?
      @events.empty?
    end

    # Clear the queue.
    #
    # Returns nothing.
    def clear
      @events.clear
    end

    # Returns the Integer length of the queue.
    def length
      @events.length
    end

    alias size length
  end

  # The Driver class is responsible for scheduling all of the events for a
  # given Task.
  class Driver
    # The Thread running the driver loop.
    attr_reader :thread

    # Instantiate a new Driver and start the scheduler loop to handle events.
    #
    # task - The Task this Driver belongs to.
    def initialize(task)
      @task = task
      @events = God::DriverEventQueue.new

      @thread = Thread.new do
        loop do
          begin
            @events.pop.handle_event
          rescue ThreadError => e
            # queue is empty
            break
          rescue Object => e
            message = format("Unhandled exception in driver loop - (%s): %s\n%s",
                             e.class, e.message, e.backtrace.join("\n"))
            applog(nil, :fatal, message)
          end
        end
      end
    end

    # Check if we're in the driver context.
    #
    # Returns true if in driver thread, false if not.
    def in_driver_context?
      Thread.current == @thread
    end

    # Clear all events for this Driver.
    #
    # Returns nothing.
    def clear_events
      @events.clear
    end

    # Shutdown the DriverEventQueue threads.
    #
    # Returns nothing.
    def shutdown
      @events.shutdown
    end

    # Queue an asynchronous message.
    #
    # name - The Symbol name of the operation.
    # args - An optional Array of arguments.
    #
    # Returns nothing.
    def message(name, args = [])
      @events.push(DriverOperation.new(@task, name, args))
    end

    # Create and schedule a new DriverEvent.
    #
    # condition - The Condition.
    # delay     - The Numeric number of seconds to delay (default: interval
    #             defined in condition).
    #
    # Returns nothing.
    def schedule(condition, delay = condition.interval)
      applog(nil, :debug, "driver schedule #{condition} in #{delay} seconds")

      @events.push(DriverEvent.new(delay, @task, condition))
    end
  end
end
