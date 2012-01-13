module God
  module Conditions
    # Trigger when a process exits.
    #
    #     +pid_file+ is the pid file of the process in question. Automatically
    #                populated for Watches.
    #
    # Examples
    #
    #   # Trigger if process exits (from a Watch).
    #   on.condition(:process_exits)
    #
    #   # Trigger if process exits (non-Watch).
    #   on.condition(:process_exits) do |c|
    #     c.pid_file = "/var/run/mongrel.3000.pid"
    #   end
    class ProcessExits < EventCondition
      # The String PID file location of the process in question. Automatically
      # populated for Watches.
      attr_accessor :pid_file

      def initialize
        self.info = "process exited"
      end

      def valid?
        true
      end

      def pid
        self.pid_file ? File.read(self.pid_file).strip.to_i : self.watch.pid
      end

      def register
        pid = self.pid

        begin
          EventHandler.register(pid, :proc_exit) do |extra|
            formatted_extra = extra.size > 0 ? " #{extra.inspect}" : ""
            self.info = "process #{pid} exited#{formatted_extra}"
            self.watch.trigger(self)
          end

          msg = "#{self.watch.name} registered 'proc_exit' event for pid #{pid}"
          applog(self.watch, :info, msg)
        rescue StandardError
          raise EventRegistrationFailedError.new
        end
      end

      def deregister
        pid = self.pid
        if pid
          EventHandler.deregister(pid, :proc_exit)

          msg = "#{self.watch.name} deregistered 'proc_exit' event for pid #{pid}"
          applog(self.watch, :info, msg)
        else
          pid_file_location = self.pid_file || self.watch.pid_file
          applog(self.watch, :error, "#{self.watch.name} could not deregister: no cached PID or PID file #{pid_file_location} (#{self.base_name})")
        end
      end
    end

  end
end
