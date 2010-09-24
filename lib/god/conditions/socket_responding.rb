module God
  module Conditions
    class SocketResponding < PollCondition
      attr_accessor :family, :addr, :port
      
      def valid?
        valid = true
        valid
      end
      
      def test
        false
      end
    end
    
  end
end
