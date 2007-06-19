if $0 == __FILE__
  require File.join(File.dirname(__FILE__), *%w[.. .. lib god])
end

RAILS_ROOT = "/Users/tom/dev/gravatar2"

God.meddle do |god|
  god.interval = 5 # seconds
  
  god.watch do |w|
    w.name = "local-3000"
    w.cwd = RAILS_ROOT
    w.start = "mongrel_rails start -P ./log/mongrel.pid -d"
    w.stop = "mongrel_rails stop -P ./log/mongrel.pid"
    w.grace = 5
    
    pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
    
    w.behavior(:clean_pid_file) do |b|
      b.pid_file = pid_file
    end
  
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
  
  god.watch do |w|    
    w.name = "local-session-cleanup"
    w.cwd = File.join(RAILS_ROOT, 'tmp/sessions')
    w.start = lambda do
      Dir['ruby_sess.*'].select { |f| File.mtime(f) < Time.now - (7 * 24 * 60 * 60) }.each { |f| File.delete(f) }
    end
    
    w.start_if do |start|
      start.condition(:always)
    end
  end
end