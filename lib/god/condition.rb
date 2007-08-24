module God
  
  class Condition < Behavior
    # Generate a Condition of the given kind. The proper class if found by camel casing the
    # kind (which is given as an underscored symbol).
    #   +kind+ is the underscored symbol representing the class (e.g. foo_bar for God::Conditions::FooBar)
    def self.generate(kind, watch)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      c = God::Conditions.const_get(sym).new
      
      unless c.kind_of?(PollCondition) || c.kind_of?(EventCondition)
        abort "Condition '#{c.class.name}' must subclass either God::PollCondition or God::EventCondition" 
      end
      
      c.watch = watch
      c
    rescue NameError
      raise NoSuchConditionError.new("No Condition found with the class name God::Conditions::#{sym}")
    end
  end
  
  class PollCondition < Condition
    # all poll conditions can specify a poll interval 
    attr_accessor :interval
    attr_accessor :transition
    
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
  
  class EventCondition < Condition
    def register
      
    end
  end
  
end