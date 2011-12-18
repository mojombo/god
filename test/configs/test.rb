ENV['GOD_TEST_RAILS_ROOT'] || abort("Set a rails root for testing in an environment variable called GOD_TEST_RAILS_ROOT")

RAILS_ROOT = ENV['GOD_TEST_RAILS_ROOT']

port = 5000

God.watch do |w|
  w.name = "local-#{port}"
  w.interval = 5.seconds
  w.start = "mongrel_rails start -P ./log/mongrel.pid -c #{RAILS_ROOT} -p #{port} -d"
  w.restart = "mongrel_rails restart -P ./log/mongrel.pid -c #{RAILS_ROOT}"
  w.stop = "mongrel_rails stop -P ./log/mongrel.pid -c #{RAILS_ROOT}"
  w.group = 'mongrels'
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
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end

  # restart if memory or cpu is too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.interval = 1
      c.above = 50.megabytes
      c.times = [3, 5]
    end

    on.condition(:cpu_usage) do |c|
      c.interval = 1
      c.above = 10.percent
      c.times = [3, 5]
    end

    on.condition(:http_response_code) do |c|
      c.host = 'localhost'
      c.port = port
      c.path = '/'
      c.code_is_not = 200
      c.timeout = 10.seconds
      c.times = [3, 5]
    end
  end
end
