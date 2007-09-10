module God
  module Conditions
    
    class ProcessExits < EventCondition
      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.watch.pid_file.nil?
        valid
      end
    
      def register
        pid = File.read(self.watch.pid_file).strip.to_i
        
        begin
          EventHandler.register(pid, :proc_exit) do
            Hub.trigger(self)
          end
        rescue StandardError
          raise EventRegistrationFailedError.new
        end
      end
      
      def deregister
        pid = File.read(self.watch.pid_file).strip.to_i
        EventHandler.deregister(pid, :proc_exit)
      end
    end
    
  end
end