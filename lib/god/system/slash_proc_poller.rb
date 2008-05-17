module God
  module System
    class SlashProcPoller < PortablePoller
      @@kb_per_page = 4 # TODO: Need to make this portable
      @@hertz = 100
      @@total_mem = nil
      
      def initialize(pid)
        super(pid)
        
        unless @@total_mem # in K
          File.open("/proc/meminfo") do |f|
            @@total_mem = f.gets.split[1]
          end
        end
      end
      
      def memory
        stat[:rss].to_i * @@kb_per_page
      end
      
      def percent_memory
        (memory / @@total_mem.to_f) * 100
      end
      
      # TODO: Change this to calculate the wma instead
      def percent_cpu
        stats = stat
        total_time = stats[:utime].to_i + stats[:stime].to_i # in jiffies
        seconds = uptime - stats[:starttime].to_i / @@hertz
        if seconds == 0
          0
        else
          ((total_time * 1000 / @@hertz) / seconds) / 10
        end
      end
      
      private
      
      # in seconds
      def uptime
        File.read('/proc/uptime').split[0].to_f
      end
      
      def stat
        stats = {}
        stats[:pid], stats[:comm], stats[:state], stats[:ppid], stats[:pgrp],
        stats[:session], stats[:tty_nr], stats[:tpgid], stats[:flags],
        stats[:minflt], stats[:cminflt], stats[:majflt], stats[:cmajflt],
        stats[:utime], stats[:stime], stats[:cutime], stats[:cstime],
        stats[:priority], stats[:nice], _, stats[:itrealvalue],
        stats[:starttime], stats[:vsize], stats[:rss], stats[:rlim],
        stats[:startcode], stats[:endcode], stats[:startstack], stats[:kstkesp],
        stats[:kstkeip], stats[:signal], stats[:blocked], stats[:sigignore],
        stats[:sigcatch], stats[:wchan], stats[:nswap], stats[:cnswap],
        stats[:exit_signal], stats[:processor], stats[:rt_priority],
        stats[:policy] = File.read("/proc/#{@pid}/stat").split
        stats
      end
    end
  end
end
