module God
  
  class Hub
    @@directory = {}
    
    def self.attach(condition, metric)
      @@directory[condition] = metric
      
      if condition.kind_of?(PollCondition)
        Timer.get.schedule(condition, 0)
      else
        condition.register
      end
    end
    
    def self.detach(condition)
      @@directory.delete(condition)
    end
    
    def self.trigger(condition)
      if condition.kind_of?(PollCondition)
        self.handle_poll(condition)
      else
        puts 'event!'
      end
    end
    
    def self.handle_poll(condition)
      Thread.new do
        metric = @@directory[condition]
        watch = metric.watch
        
        watch.mutex.synchronize do
          result = condition.test
          
          puts watch.name + ' ' + condition.class.name + " [#{result}]"
          
          condition.after
          
          p metric.destination
          
          if dest = metric.destination[result]
            watch.move(dest)
          else
            # reschedule
            puts 'reschedule'
            Timer.get.schedule(c)
          end
        end
      end
    end
  end
  
end