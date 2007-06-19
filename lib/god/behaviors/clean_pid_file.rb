module God
  module Behaviors
    
    class CleanPidFile < Behavior
      attr_accessor :pid_file
    
      def initialize
        self.pid_file = nil
      end
  
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute for :clean_pid_file") if self.pid_file.nil?
        valid
      end
  
      def before_start
        File.delete(self.pid_file) rescue nil
      end
    end
  
  end
end