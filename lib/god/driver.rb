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
    
    def handle_op
      command = @ops.pop
      @task.send(command[0], *command[1])
    end
    
    def handle_event
      # display_events
      
      if @events.first.due?
        event = @events.shift
        @task.handle_poll(event.condition)
      end
      
      # display_events
      
      # don't sleep if there is a pending event and it is due
      unless @events.first && @events.first.due?
        # puts 'sleep'
        sleep INTERVAL
      end
    end
    
    def clear_events
      @events.clear
    end
    
    def message(name, args = [])
      @ops.push([name, args])
    end
    
    # Create and register a new TimerEvent
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
    
    def display_events
      puts '+--'
      @events.each do |e|
        puts "| #{e.condition.friendly_name} - #{e.at.to_f}"
      end
      puts '+--'
    end
  end # Driver
  
end # God