God.watch do |w|
  w.name = 'child-polls'
  w.start = File.join(File.dirname(__FILE__), *%w[simple_server.rb])
  w.interval = 5
  w.grace = 2
  
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
  
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 3
      c.within = 20.seconds
      c.transition = :unmonitored
      c.retry_in = 10.seconds
      c.retry_times = 2
      c.retry_within = 5.minutes
    end
  end
end