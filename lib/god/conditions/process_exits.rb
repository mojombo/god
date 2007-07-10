module God
  module Conditions
    
    class ProcessExits < EventCondition
      attr_accessor :pid_file
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute for :process_not_running") if self.pid_file.nil?
        valid
      end
    
      def register
        pid = File.open(self.pid_file).read.strip.to_i
        EventHandler.register(pid, :proc_exit) {
          puts 'Process exited'
        }
      end
    end
    
  end
end