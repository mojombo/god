module God
  
  class Condition < Behavior
    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      God::Conditions.const_get(sym).new
    rescue NameError
      raise NoSuchConditionError.new("No Condition found with the class name God::Conditions::#{sym}")
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
  end
  
end