require File.join(File.dirname(__FILE__), *%w[.. lib god])

require 'test/unit'
require 'mocha'

include God

module God
  class ExitCalledError < StandardError
  end
  
  class Base
    def exit
      raise ExitCalledError.new("exit called")
    end
  end
  
  class FakeCondition < Condition
        
    def test
      true
    end
    
  end
end

# This allows you to be a good OOP citizen and honor encapsulation, but
# still make calls to private methods (for testing) by doing
#
#   obj.bypass.private_thingie(arg1, arg2)
#
# Which is easier on the eye than
#
#   obj.send(:private_thingie, arg1, arg2)
#
class Object
  class Bypass
    instance_methods.each do |m|
      undef_method m unless m =~ /^__/
    end

    def initialize(ref)
      @ref = ref
    end
  
    def method_missing(sym, *args)
      @ref.__send__(sym, *args)
    end
  end

  def bypass
    Bypass.new(self)
  end
end