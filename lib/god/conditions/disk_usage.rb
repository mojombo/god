module God
  module Conditions

    class DiskUsage < PollCondition
      attr_accessor :above, :mount_point

      def initialize
        super
        self.above = nil
        self.mount_point = nil
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'mount_point' must be specified", self) if self.mount_point.nil?
        valid &= complain("Attribute 'above' must be specified", self) if self.above.nil?
        valid
      end

      def test
        self.info = []
        usage = `df -P | grep -i " #{self.mount_point}$" | awk '{print $5}' | sed 's/%//'`
        if usage.to_i > self.above
          self.info = "disk space out of bounds"
          return true
        else
          return false
        end
      end
    end
  end
end
