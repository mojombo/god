God.watch do |w|
  w.name = 'child-polls'
  w.start = File.join(GOD_ROOT, *%w[test configs child_polls simple_server.rb])
  w.interval = 5
  w.grace = 2

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:cpu_usage) do |c|
      c.above = 30.percent
      c.times = [3, 5]
    end

    restart.condition(:memory_usage) do |c|
      c.above = 10.megabytes
      c.times = [3, 5]
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 3
      c.within = 60.seconds
      c.transition = :unmonitored
      c.retry_in = 10.seconds
      c.retry_times = 2
      c.retry_within = 5.minutes
    end
  end
end
