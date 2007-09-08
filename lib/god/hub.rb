module God
  
  class Hub
    class << self
      # directory to hold conditions and their corresponding metric
      # {condition => metric}
      attr_accessor :directory
    end
    
    self.directory = {}
    
    def self.attach(condition, metric)
      self.directory[condition] = metric
      
      case condition
        when PollCondition
          Timer.get.schedule(condition, 0)
        when EventCondition, TriggerCondition
          condition.register
      end
    end
    
    def self.detach(condition)
      self.directory.delete(condition)
      
      case condition
        when PollCondition
          Timer.get.unschedule(condition)
        when EventCondition, TriggerCondition
          condition.deregister
      end
    end
    
    def self.trigger(condition)
      case condition
        when PollCondition
          self.handle_poll(condition)
        when EventCondition, TriggerCondition
          self.handle_event(condition)
      end
    end
    
    def self.handle_poll(condition)
      Thread.new do
        begin
          metric = self.directory[condition]
          
          # it's possible that the timer will trigger an event before it can be cleared
          # by an exiting metric, in which case it should be ignored
          unless metric.nil?
            watch = metric.watch
            
            watch.mutex.synchronize do
              # run the test
              result = condition.test
              
              # log
              msg = watch.name + ' ' + condition.class.name + " [#{result}] " + self.dest_desc(metric, condition)
              Syslog.debug(msg)
              LOG.log(watch, :info, msg)
              
              # after-condition
              condition.after
              
              # get the destination
              dest = 
              if result && condition.transition
                # condition override
                condition.transition
              else
                # regular
                metric.destination && metric.destination[result]
              end
              
              # transition or reschedule
              if dest
                # transition
                begin
                  watch.move(dest)
                rescue EventRegistrationFailedError
                  msg = watch.name + ' Event registration failed, moving back to previous state'
                  Syslog.debug(msg)
                  LOG.log(watch, :info, msg)
                  
                  dest = watch.state
                  retry
                end
              else
                # reschedule
                Timer.get.schedule(condition)
              end
            end
          end
        rescue => e
          message = format("Unhandled exception (%s): %s\n%s",
                           e.class, e.message, e.backtrace.join("\n"))
          Syslog.crit message
          abort message
        end
      end
    end
    
    def self.handle_event(condition)
      Thread.new do
        metric = self.directory[condition]
        
        unless metric.nil?
          watch = metric.watch
        
          watch.mutex.synchronize do              
            msg = watch.name + ' ' + condition.class.name + " [true] " + self.dest_desc(metric, condition)
            Syslog.debug(msg)
            LOG.log(watch, :info, msg)
          
            # get the destination
            dest = 
            if condition.transition
              # condition override
              condition.transition
            else
              # regular
              metric.destination && metric.destination[true]
            end
            
            if dest
              watch.move(dest)
            end
          end
        end
      end
    end
    
    # helpers
  
    def self.dest_desc(metric, condition)
      if metric.destination
        metric.destination.inspect
      else
        if condition.transition
          {true => condition.transition}.inspect
        else
          'none'
        end
      end
    end
  end
  
end