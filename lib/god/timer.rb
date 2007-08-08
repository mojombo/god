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
      
      @timer = Thread.new do
        loop do
          # get the current time
          t = Time.now.to_i
          
          # iterate over each event and trigger any that are due
          @events.each do |event|
            if t >= event.at
              self.trigger(event)
              @events.delete(event)
            else
              break
            end
          end
          
          # sleep until next check
          sleep INTERVAL
        end
      end
    end
    
    # Create and register a new TimerEvent with the given parameters
    def schedule(condition, interval = condition.interval)
      @events << TimerEvent.new(condition, interval)
      @events.sort! { |x, y| x.at <=> y.at }
    end
    
    # Remove any TimerEvents for the given condition
    def unschedule(condition)
      @events.reject! { |x| x.condition == condition }
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