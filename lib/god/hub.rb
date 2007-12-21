module God
  
  class Hub
    class << self
      # directory to hold conditions and their corresponding metric
      # {condition => metric}
      attr_accessor :directory
      
      # mutex to keep the directory consistent
      attr_accessor :mutex
    end
    
    self.directory = {}
    self.mutex = Monitor.new
    
    # Attach the condition to the hub and schedule/register it
    #   +condition+ is the Condition to attach
    #   +metric+ is the Metric to which the condition belongs
    #
    # Returns nothing
    def self.attach(condition, metric)
      self.mutex.synchronize do
        self.directory[condition] = metric
        condition.reset
        
        case condition
          when PollCondition
            Timer.get.schedule(condition, 0)
          when EventCondition, TriggerCondition
            condition.register
        end
      end
    end
    
    # Detach the condition from the hub and unschedule/deregister it
    #   +condition+ is the Condition to detach
    #
    # Returns nothing
    def self.detach(condition)
      self.mutex.synchronize do
        self.directory.delete(condition)
        
        case condition
          when PollCondition
            Timer.get.unschedule(condition)
          when EventCondition, TriggerCondition
            condition.deregister
        end
      end
    end
    
    # Trigger evaluation of the condition
    #   +condition+ is the Condition to evaluate
    #
    # Returns nothing
    def self.trigger(condition)
      self.mutex.synchronize do
        case condition
          when PollCondition
            self.handle_poll(condition)
          when EventCondition, TriggerCondition
            self.handle_event(condition)
        end
      end
    end
    
    # private
    
    # Asynchronously evaluate and handle the given poll condition. Handles logging
    # notifications, and moving to the new state if necessary
    #   +condition+ is the Condition to handle
    #
    # Returns nothing
    def self.handle_poll(condition)
      metric = self.directory[condition]
      
      # it's possible that the timer will trigger an event before it can be cleared
      # by an exiting metric, in which case it should be ignored
      return if metric.nil?
      
      Thread.new do
        begin
          watch = metric.watch
          
          watch.mutex.synchronize do
            # run the test
            result = condition.test
            
            # log
            messages = self.log(watch, metric, condition, result)
            
            # notify
            if condition.notify && self.trigger?(metric, result)
              self.notify(condition, messages.last)
            end
            
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
                applog(watch, :info, msg)
                
                dest = watch.state
                retry
              end
            else
              # reschedule
              Timer.get.schedule(condition)
            end
          end
        rescue Exception => e
          message = format("Unhandled exception (%s): %s\n%s",
                           e.class, e.message, e.backtrace.join("\n"))
          applog(nil, :fatal, message)
        end
      end
    end
    
    # Asynchronously evaluate and handle the given event condition. Handles logging
    # notifications, and moving to the new state if necessary
    #   +condition+ is the Condition to handle
    #
    # Returns nothing
    def self.handle_event(condition)
      metric = self.directory[condition]
      
      # it's possible that the timer will trigger an event before it can be cleared
      # by an exiting metric, in which case it should be ignored
      return if metric.nil?
      
      Thread.new do
        begin
          watch = metric.watch
          
          watch.mutex.synchronize do
            # log
            messages = self.log(watch, metric, condition, true)
            
            # notify
            if condition.notify && self.trigger?(metric, true)
              self.notify(condition, messages.last)
            end
            
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
        rescue Exception => e
          message = format("Unhandled exception (%s): %s\n%s",
                           e.class, e.message, e.backtrace.join("\n"))
          applog(nil, :fatal, message)
        end
      end
    end
    
    # Determine whether a trigger happened
    #   +metric+ is the Metric
    #   +result+ is the result from the condition's test
    #
    # Returns Boolean
    def self.trigger?(metric, result)
      metric.destination && metric.destination[result]
    end
    
    # Log info about the condition and return the list of messages logged
    #   +watch+ is the Watch
    #   +metric+ is the Metric
    #   +condition+ is the Condition
    #   +result+ is the Boolean result of the condition test evaluation
    #
    # Returns String[]
    def self.log(watch, metric, condition, result)
      status = 
      if self.trigger?(metric, result)
        "[trigger]"
      else
        "[ok]"
      end
      
      messages = []
      
      # log info if available
      if condition.info
        Array(condition.info).each do |condition_info|
          messages << "#{watch.name} #{status} #{condition_info} (#{condition.base_name})"
          applog(watch, :info, messages.last)
        end
      else
        messages << "#{watch.name} #{status} (#{condition.base_name})"
        applog(watch, :info, messages.last)
      end
      
      # log
      debug_message = watch.name + ' ' + condition.base_name + " [#{result}] " + self.dest_desc(metric, condition)
      applog(watch, :debug, debug_message)
      
      messages
    end
    
    # Format the destination specification for use in debug logging
    #   +metric+ is the Metric
    #   +condition+ is the Condition
    #
    # Returns String
    def self.dest_desc(metric, condition)
      if condition.transition
        {true => condition.transition}.inspect
      else
        if metric.destination
          metric.destination.inspect
        else
          'none'
        end
      end
    end
    
    # Notify all recipeients of the given condition with the specified message
    #   +condition+ is the Condition
    #   +message+ is the String message to send
    #
    # Returns nothing
    def self.notify(condition, message)
      spec = Contact.normalize(condition.notify)
      unmatched = []
      
      # resolve contacts
      resolved_contacts =
      spec[:contacts].inject([]) do |acc, contact_name_or_group|
        cons = Array(God.contacts[contact_name_or_group] || God.contact_groups[contact_name_or_group])
        unmatched << contact_name_or_group if cons.empty?
        acc += cons
        acc
      end
      
      # warn about unmatched contacts
      unless unmatched.empty?
        msg = "#{condition.watch.name} no matching contacts for '#{unmatched.join(", ")}'"
        applog(condition.watch, :warn, msg)
      end
      
      # notify each contact
      resolved_contacts.each do |c|
        host = `hostname`.chomp rescue 'none'
        c.notify(message, Time.now, spec[:priority], spec[:category], host)
        
        msg = "#{condition.watch.name} #{c.info ? c.info : "notification sent for contact: #{c.name}"} (#{c.base_name})"
        
        applog(condition.watch, :info, msg % [])
      end
    end
  end
  
end