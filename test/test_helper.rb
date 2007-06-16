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
