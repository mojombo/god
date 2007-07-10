# This example shows how you might keep a local development Rails server up
# and running on your Mac.

# Run with:
# god start -c /path/to/local.god

RAILS_ROOT = "/Users/tom/dev/powerset/querytopia"

God.meddle do |god|
  god.watch do |w|
    w.name = "local-3000"
    w.interval = 5 # seconds
    w.start = "mongrel_rails start -P ./log/mongrel.pid -c #{RAILS_ROOT} -d"
    w.stop = "mongrel_rails stop -P ./log/mongrel.pid -c #{RAILS_ROOT}"
    w.grace = 5
    
    pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
    
    # clean pid files before start if necessary
    w.behavior(:clean_pid_file) do |b|
      b.pid_file = pid_file
    end
  
    # start if process is not running
    w.start_if do |start|
      start.condition(:process_exits) do |c|
        c.pid_file = pid_file
      end
    end
    
    # restart if memory or cpu is too high
    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.pid_file = pid_file
        c.above = (50 * 1024) # 50mb
        c.times = [3, 5]
      end
      
      restart.condition(:cpu_usage) do |c|
        c.pid_file = pid_file
        c.above = 10 # percent
        c.times = [3, 5]
      end
    end
  end
  
  # clear old session files
  god.watch do |w|    
    w.name = "local-session-cleanup"
    w.interval = 60 # seconds
    w.cwd = File.join(RAILS_ROOT, 'tmp/sessions')
    w.start = lambda do
      Dir['ruby_sess.*'].select { |f| File.mtime(f) < Time.now - (7 * 24 * 60 * 60) }.each { |f| File.delete(f) }
    end
    
    w.start_if do |start|
      start.condition(:always)
    end
  end
end