RAILS_ROOT = "/Users/tom/dev/gravatar2"

God.watch do |w|
  w.name = "local-3000"
  w.interval = 5.seconds # default
  w.start = "mongrel_rails start -c #{RAILS_ROOT} -P #{RAILS_ROOT}/log/mongrel.pid -p 3000 -d"
  w.stop = "mongrel_rails stop -P #{RAILS_ROOT}/log/mongrel.pid"
  w.restart = "mongrel_rails restart -P #{RAILS_ROOT}/log/mongrel.pid"
  w.pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")

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
      c.times = 5
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
      c.times = [3, 5]
    end

    # restart if the process is alive longer than an hour
    on.condition(:process_time) do |c|
      c.alive_longer_than = 1.hour
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end
