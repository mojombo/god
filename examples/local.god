# This example shows how you might keep a local development Rails server up
# and running on your Mac.

RAILS_ROOT = "/Users/tom/dev/gravatar2"

God.meddle do |god|
  god.interval = 60 # seconds
  
  god.watch do |w|
    w.name = "local-3000"
    w.cwd = RAILS_ROOT
    w.start = "mongrel_rails start -P ./log/mongrel.pid -d"
    w.stop = "mongrel_rails stop -P ./log/mongrel.pid"
    w.grace = 5
    
    pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
  
    w.start_if do |start|
      start.condition(:process_not_running) do |c|
        c.pid_file = pid_file
      end
    end
    
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
end