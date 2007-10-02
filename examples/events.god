# This example shows how you might keep a local development Rails server up
# and running on your Mac.

# Run with:
# god -c /path/to/events.god

RAILS_ROOT = ENV['GOD_TEST_RAILS_ROOT']

%w{3000 3001 3002}.each do |port|
  God.watch do |w|
    w.name = "local-#{port}"
    w.interval = 5.seconds
    w.start = "mongrel_rails start -p #{port} -P #{RAILS_ROOT}/log/mongrel.#{port}.pid -c #{RAILS_ROOT} -d"
    w.stop = "mongrel_rails stop -P #{RAILS_ROOT}/log/mongrel.#{port}.pid -c #{RAILS_ROOT}"
    w.pid_file = File.join(RAILS_ROOT, "log/mongrel.#{port}.pid")
    w.log = File.join(RAILS_ROOT, "log/commands.#{port}.log")
  
    # clean pid files before start if necessary
    w.behavior(:clean_pid_file)
  
    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end
  
    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    
      # failsafe
      on.condition(:tries) do |c|
        c.times = 8
        c.transition = :start
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_exits)
    end
  
    # restart if memory or cpu is too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.interval = 20
        c.above = 50.megabytes
        c.times = [3, 5]
      end
    
      on.condition(:cpu_usage) do |c|
        c.interval = 10
        c.above = 10.percent
        c.times = 5
      end
    
      on.condition(:http_response_code) do |c|
        c.host = 'localhost'
        c.port = port
        c.path = '/'
        c.code_is = 500
        c.timeout = 10.seconds
        c.times = [3, 5]
      end
    end
  
    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 1.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end