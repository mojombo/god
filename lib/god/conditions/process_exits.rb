module God
  module Conditions
    
    class ProcessExits < EventCondition
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute on the Watch for :process_exits") if self.watch.pid_file.nil?
        valid
      end
    
      def register
        pid = File.read(self.watch.pid_file).strip.to_i
        
        EventHandler.register(pid, :proc_exit) do
          Hub.trigger(self)
        end
      end
      
      def deregister
        pid = File.read(self.watch.pid_file).strip.to_i
        EventHandler.deregister(pid, :proc_exit)
      end
    end
    
  end
end