module God
  module Conditions

    class Always < PollCondition
      attr_accessor :what
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'what' attribute for :always") if self.what.nil?
        valid
      end
      
      def test
        @what
      end
    end
  
  end
end