module God
  module Conditions

    class FileMtime < PollCondition
      attr_accessor :path, :max_age

      def initialize
        super
        self.path = nil
        self.max_age = nil
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'path' must be specified", self) if self.path.nil?
        valid &= complain("Attribute 'max_age' must be specified", self) if self.max_age.nil?
        valid
      end

      def test
        (Time.now - File.mtime(self.path)) > self.max_age
      end
    end

  end
end


