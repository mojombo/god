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
      self.phase = condition.watch.phase
      
      now = (Time.now.to_f * 4).round / 4.0
      self.at = now + delay
    end
  end
  
  class Driver
    INTERVAL = 1
    
    # Instantiate a new Timer and start the scheduler loop to handle events
    #
    # Returns Timer
    def initialize
      @events = []
      @ops_queue = Queue.new
      @events_queue = Queue.new
      
      @timer = Thread.new do
        loop do
          # applog(nil, :debug, "timer main loop, #{@events.size} events pending")
          
          begin
            events_changed = false
            
            # pull in pending events
            while !@events_queue.empty? do
              @events << @events_queue.pop
              events_changed = true
            end
            
            # sort events if it changed
            if events_changed
              @events.sort! { |x, y| x.at <=> y.at }
            end
            
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
    
    # Create and register a new TimerEvent
    #   +condition+ is the Condition
    #   +delay+ is the number of seconds to delay (default: interval defined in condition)
    #
    # Returns nothing
    def schedule(condition, delay = condition.interval)
      applog(nil, :debug, "timer schedule #{condition} in #{delay} seconds")
      @pending_mutex.synchronize do
        @pending_events << TimerEvent.new(condition, delay)
      end
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