module God
  
  class Condition < Base
    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      God::Conditions.const_get(sym).new
    rescue NameError
      raise NoSuchConditionError.new("No Condition found with the class name God::Conditions::#{sym}")
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
    
    # Override this method in your Conditions (optional)
    def before
    end
    
    # Override this method in your Conditions (mandatory)
    #
    # Return true if the test passes (everything is ok)
    # Return false otherwise
    def test
      raise AbstractMethodNotOverriddenError.new("Condition#test must be overridden in subclasses")
    end
    
    # Override this method in your Conditions (optional)
    def after
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