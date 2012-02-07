module God
  module Conditions
    class FileTouched < PollCondition
      attr_accessor :path

      def initialize
        super
        self.path = nil
        self.max_age = nil
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'path' must be specified", self) if self.path.nil?
        valid
      end

      def test
        (Time.now - File.mtime(self.path)) <= self.interval
      end
    end
  end
end
