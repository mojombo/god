module God
  module Conditions
    
    class ProcessExits < EventCondition
      attr_accessor :pid_file
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute for :process_exits") if self.pid_file.nil?
        valid
      end
    
      def register
        pid = File.open(self.pid_file).read.strip.to_i
        
        puts "registering proc_exit for #{pid}"
        
        EventHandler.register(pid, :proc_exit) {
          puts 'proc-exit-callback'
          Hub.trigger(self)
        }
        
        puts "registered proc_exit for #{pid}"
      end
      
      def deregister
        EventHandler.deregister(pid, :proc_exit)
      end
    end
    
  end
end