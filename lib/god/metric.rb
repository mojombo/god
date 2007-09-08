module God
  
  class Metric
    attr_accessor :watch, :destination, :conditions
    
    def initialize(watch, destination = nil)
      self.watch = watch
      self.destination = destination
      self.conditions = []
    end
    
    # Instantiate a Condition of type +kind+ and pass it into the optional
    # block. Attributes of the condition must be set in the config file
    def condition(kind)
      # create the condition
      begin
        c = Condition.generate(kind, self.watch)
      rescue NoSuchConditionError => e
        abort e.message
      end
      
      # send to block so config can set attributes
      yield(c) if block_given?
      
      # call prepare on the condition
      c.prepare
      
      # abort if the Condition is invalid, the Condition will have printed
      # out its own error messages by now
      unless c.valid?
        abort "Exiting on invalid condition"
      end
      
      # inherit interval from watch if no poll condition specific interval was set
      if c.kind_of?(PollCondition) && !c.interval
        if self.watch.interval
          c.interval = self.watch.interval
        else
          abort "No interval set for Condition '#{c.class.name}' in Watch '#{self.watch.name}', and no default Watch interval from which to inherit"
        end
      end
      
      # remember
      self.conditions << c
    end
    
    def enable
      self.conditions.each do |c|
        Hub.attach(c, self)
      end
    end
    
    def disable
      self.conditions.each do |c|
        Hub.detach(c)
      end
    end
  end
  
end