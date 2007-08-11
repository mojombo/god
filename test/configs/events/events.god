God.watch do |w|
  w.name = "local-3000"
  w.interval = 5 # seconds
  w.start = File.join(File.dirname(__FILE__), *%w[simple_server.rb])
  w.stop = ""
  
  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end
  
  # determine when process has finished starting
  w.transition(:start, :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
    
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end