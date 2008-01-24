module God
  
  class DriverEvent
    attr_accessor :condition, :at, :phase
    
    # Instantiate a new TimerEvent that will be triggered after the specified delay
    #   +condition+ is the Condition
    #   +delay+ is the number of seconds from now at which to trigger
    #
    # Returns TimerEvent
    def initialize(condition, delay)
      self.condition = condition
      self.at = Time.now + delay
    end
  end
  
  class Driver
    INTERVAL = 1
    
    # Instantiate a new Driver and start the scheduler loop to handle events
    #
    # Returns Driver
    def initialize(task)
      @task = task
      @events = []
      @ops = Queue.new
      
      @timer = Thread.new do
        loop do
          # applog(nil, :debug, "timer main loop, #{@events.size} events pending")
          
          begin
            unless @op.empty?
              command = @ops.pop
              @task.send(command[0], *command[1])
              next
            end
            
            # sort events
            @events.sort! { |x, y| x.at <=> y.at }
            
            # only do this when there are events
            if @events.empty?
              sleep INTERVAL
            else
              # get the current time
              t = Time.now
              
              if t >= @events.first.at
                self.trigger(@events.pop)
              end
            end
          rescue Exception => e
            message = format("Unhandled exception (%s): %s\n%s",
                             e.class, e.message, e.backtrace.join("\n"))
            applog(nil, :fatal, message)
          end
        end
      end
    end
    
    def clear_events
      @events.each do |event|
        case event.condition
          when EventCondition, TriggerCondition
            event.condition.deregister
        end
      end
      
      @events.clear
    end
    
    # Create and register a new TimerEvent
    #   +condition+ is the Condition
    #   +delay+ is the number of seconds to delay (default: interval defined in condition)
    #
    # Returns nothing
    def schedule(condition, delay = condition.interval)
      applog(nil, :debug, "driver schedule #{condition} in #{delay} seconds")
      @events_queue << DriverEvent.new(condition, delay)
    end
    
    # Remove any TimerEvents for the given condition
    #   +condition+ is the Condition
    #
    # Returns nothing
    def unschedule(condition)
      applog(nil, :debug, "timer unschedule #{condition}")
    end
    
    # Trigger the event's condition to be evaluated
    #   +event+ is the TimerEvent to trigger
    #
    # Returns nothing
    def trigger(event)
      applog(nil, :debug, "timer trigger #{event}")
      Hub.trigger(event.condition, event.phase)
    end
    
    # Join the timer thread
    #
    # Returns nothing
    def join
      @timer.join
    end
  end
  
end