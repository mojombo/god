God.watch do |w|
  w.name = "daemon-events"
  w.interval = 5.seconds
  w.start = 'ruby ' + File.join(File.dirname(__FILE__), *%w[simple_server.rb]) + ' start'
  w.stop = 'ruby ' + File.join(File.dirname(__FILE__), *%w[simple_server_stop.rb])
  w.pid_file = '/var/run/daemon-events.pid'
  w.log = File.join(File.dirname(__FILE__), 'daemon_events.log')
  w.uid = 'tom'
  w.gid = 'tom'

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
      c.times = 2
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end
end
