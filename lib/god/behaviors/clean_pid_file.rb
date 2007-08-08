module God
  module Behaviors
    
    class CleanPidFile < Behavior
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute on the Watch for :clean_pid_file") if self.watch.pid_file.nil?
        valid
      end
  
      def before_start
        File.delete(self.watch.pid_file) rescue nil
      end
    end
  
  end
end