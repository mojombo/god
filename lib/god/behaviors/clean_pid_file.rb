module God
  module Behaviors
    
    class CleanPidFile < Behavior
      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.watch.pid_file.nil?
        valid
      end
  
      def before_start
        File.delete(self.watch.pid_file) rescue nil
      end
    end
  
  end
end