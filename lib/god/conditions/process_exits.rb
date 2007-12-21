module God
  module Conditions
    
    # Condition Symbol :process_exits
    # Type: Event
    # 
    # Trigger when a process exits.
    #
    # Paramaters
    #   Required
    #     +pid_file+ is the pid file of the process in question. Automatically
    #                populated for Watches.
    #
    # Examples
    #
    # Trigger if process exits (from a Watch):
    #
    #   on.condition(:process_exits)
    #
    # Trigger if process exits:
    #
    #   on.condition(:process_exits) do |c|
    #     c.pid_file = "/var/run/mongrel.3000.pid"
    #   end
    class ProcessExits < EventCondition
      def initialize
        self.info = "process exited"
      end
      
      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.watch.pid_file.nil?
        valid
      end
    
      def register
        pid = File.read(self.watch.pid_file).strip.to_i
        
        begin
          EventHandler.register(pid, :proc_exit) do |extra|
            formatted_extra = extra.size > 0 ? " #{extra.inspect}" : ""
            self.info = "process #{pid} exited#{formatted_extra}"
            Hub.trigger(self)
          end
          
          msg = "#{self.watch.name} registered 'proc_exit' event for pid #{pid}"
          applog(self.watch, :info, msg)
        rescue StandardError
          raise EventRegistrationFailedError.new
        end
      end
      
      def deregister
        if File.exist?(self.watch.pid_file)
          pid = File.read(self.watch.pid_file).strip.to_i
          EventHandler.deregister(pid, :proc_exit)
          
          msg = "#{self.watch.name} deregistered 'proc_exit' event for pid #{pid}"
          applog(self.watch, :info, msg)
        else
          applog(self.watch, :error, "#{self.watch.name} could not deregister: no such PID file #{self.watch.pid_file} (#{self.base_name})")
        end
      end
    end
    
  end
end