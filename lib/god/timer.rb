module God
  
  # class TimerEvent
  #   attr_accessor :name, :at
  #   
  #   def initialize(name, at)
  #     self.name = name
  #     self.at = at
  #   end
  # end
  
  class Timer < Base
    INTERVAL = 0.25
    
    attr_reader :events
    
    def initialize
      @events = {}
      
      @timer = Thread.new do
        t = Time.now.to_i
        
        loop do
          @events.each do |name, at|
            if t >= at
              @events.delete(name)
            end
          end
          
          # sleep until next check
          sleep INTERVAL
        end
      end
    end
    
    # Register the given +name+ to trigger a 'poll' event in +delay+ seconds
    def register(name, delay)
      @events[name] = Time.now.to_i + delay
    end
    
    # 
    def join
      @timer.join
    end
  end
  
end