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

      # Memory usage in kilobytes (resident set size), including all child
      # processes
      def family_memory
        family.map { |pid| fetch_system_poller.new(pid).memory } .reduce(:+)
      end
      
      # Percentage memory usage
      def percent_memory
        @poller.percent_memory
      end
      
      # Percentage CPU usage
      def percent_cpu
        @poller.percent_cpu
      end

      # Percentage CPU usage including all child processes
      def family_percent_cpu
        family.map { |pid| fetch_system_poller.new(pid).percent_cpu } .reduce(:+)
      end
      
      private
      
      def fetch_system_poller
        if SlashProcPoller.usable?
          SlashProcPoller
        else
          PortablePoller
        end
      end
  
      # Returns an array of PIDs of the polled process and all its children.
      def family
        stack = [@pid]
        n = 0
        while stack.count > n
          pid = stack[n]
          output = `ps -e -oppid=,pid= | grep '^#{pid}'`
          children = output.split("\n").map { |x| x.sub(/^\d+\s/, '').to_i }
          stack += children
          n += 1
        end
        stack
      end
    end
  end
end
