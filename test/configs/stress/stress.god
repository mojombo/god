('01'..'08').each do |i|
  God.watch do |w|
    w.name = "stress-#{i}"
    w.start = "ruby " + File.join(File.dirname(__FILE__), *%w[simple_server.rb])
    w.interval = 0
    w.grace = 2
    w.group = 'test'

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
