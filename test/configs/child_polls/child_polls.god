God.watch do |w|
  w.name = 'child-polls'
  w.start = File.join(File.dirname(__FILE__), *%w[simple_server.rb])
  w.stop = ''
  w.interval = 5
  w.grace = 2
  w.uid = 'tom'
  w.gid = 'tom'
  w.group = 'test'
  
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end