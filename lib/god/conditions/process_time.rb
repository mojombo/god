module God
  module Conditions

    # Condition Symbol :process_time
    # Type: Poll
    #
    # Paramaters
    #   Required
    #     +pid_file+ is the pid file of the process in question. Automatically
    #                populated for Watches.
    #     +alive_longer_than+ is the amount of wall time the process is allowed 
    #             to live for
    # Examples
    #
    # Trigger if the process is running for longer than 1 hour
    #
    #   on.condition(:process_time) do |c|
    #     c.alive_longer_than = 1.hour
    #   end
    #
    class ProcessTime < PollCondition
      attr_accessor :alive_longer_than, :pid_file

      def initialize
        super
        self.alive_longer_than = nil
      end

      def pid
        self.pid_file ? File.read(self.pid_file).strip.to_i : self.watch.pid
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.pid_file.nil? && self.watch.pid_file.nil?
        valid &= complain("Attribute 'alive_longer_than' must be specified", self) if self.alive_longer_than.nil?
        valid
      end

      def test
        process = System::Process.new(self.pid)
        process.elapsed_time > self.alive_longer_than
      end
    end

  end
end
