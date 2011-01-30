module God
  module System

    class PortablePoller

      def initialize(pid)
        @pid = pid
      end
      # Memory usage in kilobytes (resident set size)
      def memory
        ps_command('rss').to_i
      end

      # Percentage memory usage
      def percent_memory
        ps_command('%mem').to_f
      end

      # Percentage CPU usage
      def percent_cpu
        ps_command('%cpu').to_f
      end

      private

      def ps_command(keyword)
        `ps -o #{keyword}= -p #{@pid}`
      end

    end

  end
end