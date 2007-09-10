module God
  module Conditions
    
    class Lambda < PollCondition
      attr_accessor :lambda

      def valid?
        valid = true
        valid &= complain("Attribute 'lambda' must be specified", self) if self.lambda.nil?
        valid
      end

      def test
        self.lambda.call()
      end
    end

  end
end