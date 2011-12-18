module God
  module System

    class Process
      def self.fetch_system_poller
        @@poller ||= if SlashProcPoller.usable?
		       SlashProcPoller
		     else
		       PortablePoller
		     end
      end

      def initialize(pid)
        @pid = pid.to_i
        @poller = self.class.fetch_system_poller.new(@pid)
      end

      # Return true if this process is running, false otherwise
      def exists?
        !!::Process.kill(0, @pid) rescue false
      end

      # Memory usage in kilobytes (resident set size)
      def memory
        @poller.memory
      end

      # Percentage memory usage
      def percent_memory
        @poller.percent_memory
      end

      # Percentage CPU usage
      def percent_cpu
        @poller.percent_cpu
      end

      private

      def fetch_system_poller
        if SlashProcPoller.usable?
          SlashProcPoller
        else
          PortablePoller
        end
      end
    end

  end
end
