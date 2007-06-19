module God
  
  class Behavior < Base
    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      God::Behaviors.const_get(sym).new
    rescue NameError
      raise NoSuchBehaviorError.new("No Behavior found with the class name God::Behaviors::#{sym}")
    end
    
    # Override this method in your Conditions (optional)
    #
    # Called once after the Condition has been sent to the block and attributes have been
    # set. Do any post-processing on attributes here
    def prepare
      
    end
    
    # Override this method in your Conditions (optional)
    #
    # Called once during evaluation of the config file.
    # If invalid attributes are found, use #complain('text') to print out the error message
    def valid?
      true
    end
    
    #######
    
    def before_start
    end
    
    def after_start
    end
    
    def before_restart
    end
    
    def after_restart
    end
    
    def before_stop
    end
    
    def after_stop
    end
    
    protected
    
    def complain(text)
      puts text
      false
    end
  end
  
end