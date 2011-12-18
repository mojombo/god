module God
  module Conditions

    # Condition Symbol :process_running
    # Type: Poll
    #
    # Trigger when a process is running or not running depending on attributes.
    #
    # Paramaters
    #   Required
    #     +pid_file+ is the pid file of the process in question. Automatically
    #                populated for Watches.
    #     +running" specifies whether you want to trigger if the process is
    #               running (true) or whether it is not running (false)
    #
    # Examples
    #
    # Trigger if process IS NOT running (from a Watch):
    #
    #   on.condition(:process_running) do |c|
    #     c.running = false
    #   end
    #
    # Trigger if process IS running (from a Watch):
    #
    #   on.condition(:process_running) do |c|
    #     c.running = true
    #   end
    #
    # Non-Watch Tasks must specify a PID file:
    #
    #   on.condition(:process_running) do |c|
    #     c.running = false
    #     c.pid_file = "/var/run/mongrel.3000.pid"
    #   end
    class ProcessRunning < PollCondition
      attr_accessor :running, :pid_file

      def pid
        self.pid_file ? File.read(self.pid_file).strip.to_i : self.watch.pid
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.pid_file.nil? && self.watch.pid_file.nil?
        valid &= complain("Attribute 'running' must be specified", self) if self.running.nil?
        valid
      end

      def test
        self.info = []

        pid = self.pid
        active = pid && System::Process.new(pid).exists?

        if (self.running && active)
          self.info.concat(["process is running"])
          true
        elsif (!self.running && !active)
          self.info.concat(["process is not running"])
          true
        else
          if self.running
            self.info.concat(["process is not running"])
          else
            self.info.concat(["process is running"])
          end
          false
        end
      end
    end

  end
end
