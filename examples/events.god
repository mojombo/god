# This example shows how you might keep a local development Rails server up
# and running on your Mac.

# Run with:
# god -c /path/to/events.god

RAILS_ROOT = "/Users/tom/dev/helloworld"

God.meddle do |god|
  god.watch do |w|
    w.name = "local-3000"
    w.interval = 5 # seconds
    w.start = "mongrel_rails start -P ./log/mongrel.pid -c #{RAILS_ROOT} -d"
    w.stop = "mongrel_rails stop -P ./log/mongrel.pid -c #{RAILS_ROOT}"
    
    pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
    
    # clean pid files before start if necessary
    w.behavior(:clean_pid_file) do |b|
      b.pid_file = pid_file
    end
    
    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.pid_file = pid_file
      end
    end
    
    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.pid_file = pid_file
      end
    end
  
    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_exits) do |c|
        c.pid_file = pid_file
      end
    end
    
    # restart if memory or cpu is too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.interval = 20
        c.pid_file = pid_file
        c.above = (50 * 1024) # 50mb
        c.times = [3, 5]
      end
      
      on.condition(:cpu_usage) do |c|
        c.interval = 10
        c.pid_file = pid_file
        c.above = 10 # percent
        c.times = [3, 5]
      end
    end
  end
end