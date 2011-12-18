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
        if self.lambda.call()
          self.info = "lambda condition was satisfied"
          true
        else
          self.info = "lambda condition was not satisfied"
          false
        end
      end
    end

  end
end
