module God
  module Conditions

    class Always < PollCondition
      attr_accessor :what

      def initialize
        self.info = "always"
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'what' must be specified", self) if self.what.nil?
        valid
      end

      def test
        @what
      end
    end

  end
end
