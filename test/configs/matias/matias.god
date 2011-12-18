$pid_file = "/tmp/matias.pid"

God.task do |w|
  w.name = "watcher"
  w.interval = 5.seconds
  w.valid_states = [:init, :up, :down]
  w.initial_state = :init

  # determine the state on startup
  w.transition(:init, { true => :up, false => :down }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.pid_file = $pid_file
    end
  end

  # when process is up
  w.transition(:up, :down) do |on|
    # transition to 'start' if process goes down
    on.condition(:process_running) do |c|
      c.running = false
      c.pid_file = $pid_file
    end

    # send up info
    on.condition(:lambda) do |c|
      c.lambda = lambda do
        puts 'yay I am up'
        false
      end
    end
  end

  # when process is down
  w.transition(:down, :up) do |on|
    # transition to 'up' if process comes up
    on.condition(:process_running) do |c|
      c.running = true
      c.pid_file = $pid_file
    end

    # send down info
    on.condition(:lambda) do |c|
      c.lambda = lambda do
        puts 'boo I am down'
        false
      end
    end
  end
end
