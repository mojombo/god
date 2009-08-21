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
        usage = `df -P | grep -i " #{self.mount_point}$" | awk '{print $5}' | sed 's/%//'`
        usage.to_i > self.above
      end
    end
    
  end
end
