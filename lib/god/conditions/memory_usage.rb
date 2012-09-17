module God
  module Conditions

    # Condition Symbol :memory_usage
    # Type: Poll
    #
    # Trigger when the resident memory of a process is above a specified limit.
    #
    # Paramaters
    #   Required
    #     +pid_file+ is the pid file of the process in question. Automatically
    #                populated for Watches.
    #     +above+ is the amount of resident memory (in kilobytes) above which
    #             the condition should trigger. You can also use the sugar
    #             methods #kilobytes, #megabytes, and #gigabytes to clarify
    #             this amount (see examples).
    #
    # Examples
    #
    # Trigger if the process is using more than 100 megabytes of resident
    # memory (from a Watch):
    #
    #   on.condition(:memory_usage) do |c|
    #     c.above = 100.megabytes
    #   end
    #
    # Non-Watch Tasks must specify a PID file:
    #
    #   on.condition(:memory_usage) do |c|
    #     c.above = 100.megabytes
    #     c.pid_file = "/var/run/mongrel.3000.pid"
    #   end
    class MemoryUsage < PollCondition
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
        process = System::Process.new(self.pid)
        @timeline.push(process.memory)
        self.info = []

        history = "[" + @timeline.map { |x| "#{x > self.above ? '*' : ''}#{x}kb" }.join(", ") + "]"

        if @timeline.select { |x| x > self.above }.size >= self.times.first
          self.info = "memory out of bounds #{history}"
          return true
        else
          return false
        end
      end
    end

  end
end
