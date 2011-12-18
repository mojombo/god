God.watch do |w|
  w.name = "child-events"
  w.interval = 5.seconds
  w.start = File.join(GOD_ROOT, *%w[test configs child_events simple_server.rb])
  # w.log = File.join(GOD_ROOT, *%w[test configs child_events god.log])

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
      c.times = 2
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 20.seconds
      c.transition = :unmonitored
      c.retry_in = 10.seconds
      c.retry_times = 2
      c.retry_within = 5.minutes
    end
  end
end
