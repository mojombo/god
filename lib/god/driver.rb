module God
  
  class DriverEvent
    attr_accessor :condition, :at
    
    # Instantiate a new TimerEvent that will be triggered after the specified delay
    #   +condition+ is the Condition
    #   +delay+ is the number of seconds from now at which to trigger
    #
    # Returns TimerEvent
    def initialize(condition, delay)
      self.condition = condition
      self.at = Time.now + delay
    end
    
    def due?
      Time.now >= self.at
    end
  end # DriverEvent
  
  class Driver
    attr_reader :thread
    
    INTERVAL = 0.25
    
    # Instantiate a new Driver and start the scheduler loop to handle events
    #   +task+ is the Task this Driver belongs to
    #
    # Returns Driver
    def initialize(task)
      @task = task
      @events = []
      @ops = Queue.new
      
      @thread = Thread.new do
        loop do
          begin
            if !@ops.empty?
              self.handle_op
            elsif !@events.empty?
              self.handle_event
            else
              sleep INTERVAL
            end
          rescue Exception => e
            message = format("Unhandled exception in driver loop - (%s): %s\n%s",
                             e.class, e.message, e.backtrace.join("\n"))
            applog(nil, :fatal, message)
          end
        end
      end
    end
    
    # Handle the next queued operation that was issued asynchronously
    #
    # Returns nothing
    def handle_op
      command = @ops.pop
      @task.send(command[0], *command[1])
    end
    
    # Handle the next event (poll condition) that is due
    #
    # Returns nothing
    def handle_event
      if @events.first.due?
        event = @events.shift
        @task.handle_poll(event.condition)
      end
      
      # don't sleep if there is a pending event and it is due
      unless @events.first && @events.first.due?
        sleep INTERVAL
      end
    end
    
    # Clear all events for this Driver
    #
    # Returns nothing
    def clear_events
      @events.clear
    end
    
    # Queue an asynchronous message
    #   +name+ is the Symbol name of the operation
    #   +args+ is an optional Array of arguments
    #
    # Returns nothing
    def message(name, args = [])
      @ops.push([name, args])
    end
    
    # Create and schedule a new DriverEvent
    #   +condition+ is the Condition
    #   +delay+ is the number of seconds to delay (default: interval defined in condition)
    #
    # Returns nothing
    def schedule(condition, delay = condition.interval)
      applog(nil, :debug, "driver schedule #{condition} in #{delay} seconds")
      
      @events.concat([DriverEvent.new(condition, delay)])
      
      # sort events
      @events.sort! { |x, y| x.at <=> y.at }
    end
  end # Driver
  
end # God