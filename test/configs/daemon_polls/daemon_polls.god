God.watch do |w|
  w.name = "daemon-polls"
  w.interval = 5.seconds
  w.start = 'ruby ' + File.join(File.dirname(__FILE__), *%w[simple_server.rb]) + ' start'
  w.stop = 'ruby ' + File.join(File.dirname(__FILE__), *%w[simple_server.rb]) + ' stop'
  w.pid_file = '/var/run/daemon-polls.pid'
  w.start_grace = 2.seconds
  w.log = File.join(File.dirname(__FILE__), *%w[out.log])

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end
end
