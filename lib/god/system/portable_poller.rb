module God
  module System
    class PortablePoller
      def initialize(pid)
        @pid = pid
      end
      # Memory usage in kilobytes (resident set size)
      def memory
        ps_int('rss')
      end

      # Percentage memory usage
      def percent_memory
        ps_float('%mem')
      end

      # Percentage CPU usage
      def percent_cpu
        ps_float('%cpu')
      end

      # Wall time a process has been running for
      def elapsed_time
        ps_seconds('etime')
      end

      private

      def ps_int(keyword)
        `ps -o #{keyword}= -p #{@pid}`.to_i
      end

      def ps_float(keyword)
        `ps -o #{keyword}= -p #{@pid}`.to_f
      end

      def ps_string(keyword)
        `ps -o #{keyword}= -p #{@pid}`.strip
      end

      def ps_seconds(keyword)
        time_string_to_seconds(ps_string(keyword))
      end

      def time_string_to_seconds(text)
        units = [1.second, 1.minute, 1.hour, 1.day]
        times = text.scan(/[0-9]+/)
        times.reverse.map{|s| s.to_i}.zip(units).map{|p| p.reduce(:*)}.reduce(:+)
      end

    end
  end
end
