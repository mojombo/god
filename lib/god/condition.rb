module God
  
  class Condition < Behavior
    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      cond = God::Conditions.const_get(sym).new
      
      unless cond.kind_of?(PollCondition) || cond.kind_of?(EventCondition)
        abort "Condition '#{cond.class.name}' must subclass either God::PollCondition or God::EventCondition" 
      end
      
      cond
    rescue NameError
      raise NoSuchConditionError.new("No Condition found with the class name God::Conditions::#{sym}")
    end
  end
  
  class PollCondition < Condition
    # all poll conditions can specify a poll interval 
    attr_accessor :interval
    
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