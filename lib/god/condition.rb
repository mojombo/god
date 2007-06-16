module God
  
  class Condition
    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      God.const_get(sym).new
    rescue NameError
      raise NoSuchConditionError.new("No Condition found with the class name God::#{sym}")
    end
    
    def valid?
      true
    end
    
    def before
    end
    
    def test
      raise AbstractMethodNotOverriddenError.new("Condition#test must be overridden in subclasses")
    end
    
    def after
    end
    
    protected
    
    def complain(text)
      puts text
      false
    end
  end
  
end