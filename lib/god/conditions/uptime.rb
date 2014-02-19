module God
  module Conditions

    # Condition Symbol :uptime
    # Type: Poll
    #
    # Trigger when the process uptime is higher than allowed.
    #
    # Paramaters
    #   Required
    #     +pid_file+ is the pid file of the process in question. Automatically
    #                populated for Watches.
    #     +above+ is the amount of uptime (in seconds) above which
    #             the condition should trigger. You can also use the sugar
    #             methods #minutes, #houres, and #days to clarify
    #             this amount (see examples).
    #
    # Examples
    #
    # Trigger if the process uptime is above 20 minutes (from a Watch):
    #
    #   on.condition(:uptime) do |c|
    #     c.above = 20.minutes
    #   end
    #
    # Non-Watch Tasks must specify a PID file:
    #
    #   on.condition(:memory_usage) do |c|
    #     c.above = 20.minutes
    #     c.pid_file = "/var/run/mongrel.3000.pid"
    #   end
    class Uptime < PollCondition
      attr_accessor :above, :times, :pid_file

      def initialize
        super
        self.above = nil
        self.times = [1, 1]
      end

      def prepare
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end

        @timeline = Timeline.new(self.times[1])
      end

      def reset
        @timeline.clear
      end

      def pid
        self.pid_file ? File.read(self.pid_file).strip.to_i : self.watch.pid
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.pid_file.nil? && self.watch.pid_file.nil?
        valid &= complain("Attribute 'above' must be specified", self) if self.above.nil?
        valid
      end

      def test
        if uptime = System::Process.new(self.pid).uptime_seconds > self.above
          self.info = "uptime #{uptime} > #{self.above}"
          return true
        else
          return false
        end
      end
    end

  end
end
