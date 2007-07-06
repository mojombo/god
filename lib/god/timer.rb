module God
  
  class TimerEvent
    attr_accessor :watch, :condition, :command, :at
    
    def initialize(watch, condition, command)
      self.watch = watch
      self.condition = condition
      self.command = command
      self.at = Time.now.to_i + condition.interval
    end
  end
  
  class Timer < Base
    INTERVAL = 0.25
    
    attr_reader :events
    
    def initialize
      @events = []
      
      @timer = Thread.new do
        loop do
          t = Time.now.to_i
          
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
    def register(watch, condition, command)
      @events << TimerEvent.new(watch, condition, command)
      @events.sort! { |x, y| x.at <=> y.at }
    end
    
    def trigger(event)
      timer = self
      
      Thread.new do
        w = event.watch
        c = event.condition
        
        w.mutex.synchronize do
          if c.test
            puts w.name + ' ' + c.class.name + ' [ok]'
          else
            puts w.name + ' ' + c.class.name + ' [fail]'
            c.after
            w.action(event.command, c)
          end
        end
        
        # reschedule
        timer.register(w, c, event.command)
      end
    end
    
    # 
    def join
      @timer.join
    end
  end
  
end