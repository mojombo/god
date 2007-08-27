if $0 == __FILE__
  require File.join(File.dirname(__FILE__), *%w[.. .. lib god])
end

ENV['GOD_TEST_RAILS_ROOT'] || abort("Set a rails root for testing in an environment variable called GOD_TEST_RAILS_ROOT")

RAILS_ROOT = ENV['GOD_TEST_RAILS_ROOT']

God.init do |g|
  # g.host = 
  # g.port = 7777
  # g.pid_file_directory = 
end

class SimpleNotifier
  def self.notify(str)
    puts "Notifying: #{str}"
  end
end

God.watch do |w|
  w.name = "local-3000"
  w.interval = 5.seconds
  w.start = "mongrel_rails start -P ./log/mongrel.pid -c #{RAILS_ROOT} -p 3001 -d"
  w.restart = "mongrel_rails restart -P ./log/mongrel.pid -c #{RAILS_ROOT}"
  w.stop = "mongrel_rails stop -P ./log/mongrel.pid -c #{RAILS_ROOT}"
  w.restart_grace = 5.seconds
  w.stop_grace = 5.seconds
  w.autostart = true
  w.uid = 'kev'
  w.gid = 'kev'
  w.group = 'mongrels'
  w.pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
  
  # clean pid files before start if necessary
  w.behavior(:clean_pid_file)
  
  w.behavior(:notify_when_flapping) do |b|
    b.failures = 5
    b.seconds = 60.seconds
    b.notifier = SimpleNotifier
  end
  
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
  end
end