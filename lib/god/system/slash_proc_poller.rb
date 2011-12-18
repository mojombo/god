module God
  module System
    class SlashProcPoller < PortablePoller
      @@kb_per_page = 4 # TODO: Need to make this portable
      @@hertz = 100
      @@total_mem = nil

      MeminfoPath = '/proc/meminfo'
      UptimePath = '/proc/uptime'

      RequiredPaths = [MeminfoPath, UptimePath]

      # FreeBSD has /proc by default, but nothing mounted there!
      # So we should check for the actual required paths!
      # Returns true if +RequiredPaths+ are readable.
      def self.usable?
        RequiredPaths.all? do |path|
          test(?r, path) && readable?(path)
        end
      end

      def initialize(pid)
        super(pid)

        unless @@total_mem # in K
          File.open(MeminfoPath) do |f|
            @@total_mem = f.gets.split[1]
          end
        end
      end

      def memory
        stat[:rss].to_i * @@kb_per_page
      rescue # This shouldn't fail is there's an error (or proc doesn't exist)
        0
      end

      def percent_memory
        (memory / @@total_mem.to_f) * 100
      rescue # This shouldn't fail is there's an error (or proc doesn't exist)
        0
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
      rescue # This shouldn't fail is there's an error (or proc doesn't exist)
        0
      end

      private

      # Some systems (CentOS?) have a /proc, but they can hang when trying to
      # read from them. Try to use this sparingly as it is expensive.
      def self.readable?(path)
        begin
          timeout(1) { File.read(path) }
        rescue Timeout::Error
          false
        end
      end

      # in seconds
      def uptime
        File.read(UptimePath).split[0].to_f
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
        stats[:policy] = File.read("/proc/#{@pid}/stat").scan(/\(.*?\)|\w+/)
        stats
      end
    end
  end
end
