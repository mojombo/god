module God
  
  class Hub
    # directory to hold conditions and their corresponding metric
    #   key: condition
    #   val: metric
    @@directory = {}
    
    def self.attach(condition, metric)
      # add the condition to the directory
      @@directory[condition] = metric
      
      # schedule poll condition
      # register event condition
      if condition.kind_of?(PollCondition)
        Timer.get.schedule(condition, 0)
      else
        condition.register
      end
    end
    
    def self.detach(condition)
      # remove the condition from the directory
      @@directory.delete(condition)
      
      # deregister event condition
      if condition.kind_of?(EventCondition)
        condition.deregister
      end
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
            Timer.get.schedule(condition)
          end
        end
      end
    end
  end
  
end