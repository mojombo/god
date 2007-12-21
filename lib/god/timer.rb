module God
  
  class TimerEvent
    attr_accessor :condition, :at
    
    def initialize(condition, interval)
      self.condition = condition
      self.at = Time.now.to_i + interval
    end
  end
  
  class Timer
    INTERVAL = 0.25
    
    attr_reader :events, :timer
    
    @@timer = nil
    
    def self.get
      @@timer ||= Timer.new
    end
    
    def self.reset
      @@timer = nil
    end
    
    # Start the scheduler loop to handle events
    def initialize
      @events = []
      @mutex = Mutex.new
      
      @timer = Thread.new do
        loop do
          begin
            # get the current time
            t = Time.now.to_i
            
            # iterate over each event and trigger any that are due
            @mutex.synchronize do
              triggered = []
              
              @events.each do |event|
                if t >= event.at
                  # trigger the event and mark it for removal
                  self.trigger(event)
                  triggered << event
                else
                  # events are ordered, so we can bail on first miss
                  break
                end
              end
              
              # remove all triggered events
              triggered.each do |event|
                @events.delete(event)
              end
            end
          rescue Exception => e
            message = format("Unhandled exception (%s): %s\n%s",
                             e.class, e.message, e.backtrace.join("\n"))
            applog(nil, :fatal, message)
          ensure
            # sleep until next check
            sleep INTERVAL
          end
        end
      end
    end
    
    # Create and register a new TimerEvent with the given parameters
    def schedule(condition, interval = condition.interval)
      @mutex.synchronize do
        @events << TimerEvent.new(condition, interval)
        @events.sort! { |x, y| x.at <=> y.at }
      end
    end
    
    # Remove any TimerEvents for the given condition
    def unschedule(condition)
      @mutex.synchronize do
        @events.reject! { |x| x.condition == condition }
      end
    end
    
    def trigger(event)
      Hub.trigger(event.condition)
    end
    
    # Join the timer thread
    def join
      @timer.join
    end
  end
  
end