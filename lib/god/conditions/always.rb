module God
  module Conditions
    # Always trigger or never trigger.
    #
    # Examples
    #
    #   # Always trigger.
    #   on.condition(:always) do |c|
    #     c.what = true
    #   end
    #
    #   # Never trigger.
    #   on.condition(:always) do |c|
    #     c.what = false
    #   end
    class Always < PollCondition
      # The Boolean determining whether this condition will always trigger
      # (true) or never trigger (false).
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
