RAILS_ROOT = "/var/www/gravatar2/current"

settings do |s|
  s.interval = 60_000
end

%w{8000 8001 8002}.each do |port|
  watch do |w|
    w.name = "gravatar2-mongrel-#{port}"
    w.cwd = RAILS_ROOT
    w.start = "mongrel_rails cluster::start"
    w.stop = "mongrel_rails cluster::stop"
    
    w.ressurect do |r|
      r.condition(:process_not_running) do |c|
        w.pid_file = File.join(RAILS_ROOT, "log/mongrel.#{port}.pid")
        w.clean = true
      end
      
      r.condition(:runaway_memory_usage) do |c|
        c.max = 300
        c.times = [3, 5]
      end
      
      r.condition(:runaway_cpu_usage) do |c|
        c.max = 30 # percent
        c.times = 5
      end
      
      r.condition(:no_http_response) do |c|
        c.url = "http://localhost:#{port}/"
        c.status = 200
        c.timeout = 10_000
        c.times = 2
      end
    end
  end
end