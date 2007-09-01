module God
  module System
  
    class Process
      def initialize(pid)
        @pid = pid.to_i
      end
      
      # Return true if this process is running, false otherwise
      def exists?
        system("kill -0 #{@pid} &> /dev/null")
      end
      
      def kill
        system("kill -9 `cat #{@pid}`")
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
      
      # Seconds of CPU time (accumulated cpu time, user + system)
      def cpu_time
        time_string_to_seconds(ps_string('time'))
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