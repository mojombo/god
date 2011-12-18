God.watch do |w|
  w.name = 'degrading-lambda'
  w.start = 'ruby ' + File.join(File.dirname(__FILE__), *%w[tcp_server.rb])
  w.interval = 5
  w.grace = 2
  w.group = 'test'

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:degrading_lambda) do |c|
      require 'socket'
      c.lambda = lambda {
        begin
          sock = TCPSocket.open('127.0.0.1', 9090)
          sock.send "2\n", 0
          retval = sock.gets
          puts "Retval is #{retval}"
          sock.close
          retval
        rescue
          false
        end
      }
    end
  end
end
