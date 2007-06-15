module God
  
  class Condition
    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      God.const_get(sym).new
    end
    
    def before
    end
    
    def test
      raise AbstractMethodNotOverriddenError.new("test must be overridden in subclasses of Condition")
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