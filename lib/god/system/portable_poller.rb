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

      # Process uptime in seconds
      def uptime
        if gs = ps_string('etime').match(/(([0-9]+)-)?([0-9]{2}:)?([0-9]{2}):([0-9]{2})/)
          gs[2].to_i * 86400 + gs[4].to_i * 3600 + gs[5].to_i * 60 + gs[6]
        else
          0
        end
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

      def time_string_to_seconds(text)
        _, minutes, seconds, useconds = *text.match(/(\d+):(\d{2}).(\d{2})/)
        (minutes.to_i * 60) + seconds.to_i
      end
    end
  end
end
