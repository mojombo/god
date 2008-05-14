module God
  module System
  
    class Process
      def initialize(pid)
        @pid = pid.to_i
        @poller = fetch_system_poller
      end
      
      # Return true if this process is running, false otherwise
      def exists?
        !!Process.kill(0, @pid) rescue false
      end
      
      # Memory usage in kilobytes (resident set size)
      def memory
        @poller.memory(@pid)
      end
      
      # Percentage memory usage
      def percent_memory
        @poller.percent_memory(@pid)
      end
      
      # Percentage CPU usage
      def percent_cpu
        @poller.percent_cpu(@pid)
      end
      
      private
      
      def fetch_system_poller
        if test(?d, '/proc')
          SlashProcPoller
        else
          PortablePoller
        end
      end
    end
  
  end
end