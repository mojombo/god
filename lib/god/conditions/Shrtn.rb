module God
  module Conditions
    class Shrtn < PollCondition
      attr_accessor :shellcmd

      def valid?
        valid = true
        valid &= complain("Attribute 'shellcmd' must be specified", self) if self.shellcmd.nil?
        valid
      end

      def test
      system "#{shellcmd}"
        if $? == 0
          self.info = "OK"
          false
        else
          self.info = "Process has currently been found not running"
          true
        end
      end
    end
  end
end
