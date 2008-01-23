module God
  module CLI
    
    class Command
      def initialize(command, options, args)
        @command = command
        @options = options
        @args = args
        
        dispatch
      end
      
      def setup
        # connect to drb unix socket
        DRb.start_service
        @server = DRbObject.new(nil, God::Socket.socket(@options[:port]))
        
        # ping server to ensure that it is responsive
        begin
          @server.ping
        rescue DRb::DRbConnError
          puts "The server is not available (or you do not have permissions to access it)"
          abort
        end
      end
      
      def dispatch
        if %w{load status log quit terminate}.include?(@command)
          setup
          send("#{@command}_command")
        elsif %w{start stop restart monitor unmonitor remove}.include?(@command)
          setup
          lifecycle_command
        elsif @command == 'check'
          check_command
        else
          puts "Command '#{@command}' is not valid. Run 'god --help' for usage"
          abort
        end
      end
      
      def load_command
        file = @args[1]
          
        puts "Sending '#{@command}' command"
        puts
        
        unless File.exist?(file)
          abort "File not found: #{file}"
        end
        
        names, errors = *@server.running_load(File.read(file), File.expand_path(file))
        
        # output response
        unless names.empty?
          puts 'The following tasks were affected:'
          names.each do |w|
            puts '  ' + w
          end
        end
        
        unless errors.empty?
          puts errors
          exit(1)
        end
      end
      
      def status_command
        watches = @server.status
        watches.keys.sort.each do |name|
          state = watches[name][:state]
          puts "#{name}: #{state}"
        end
      end
      
      def log_command
        begin
          Signal.trap('INT') { exit }
          name = @args[1]
          
          unless name
            puts "You must specify a Task or Group name"
            exit!
          end
          
          t = Time.at(0)
          loop do
            print @server.running_log(name, t)
            t = Time.now
            sleep 1
          end
        rescue God::NoSuchWatchError
          puts "No such watch"
        rescue DRb::DRbConnError
          puts "The server went away"
        end
      end
      
      def quit_command
        begin
          @server.terminate
          abort 'Could not stop god'
        rescue DRb::DRbConnError
          puts 'Stopped god'
        end
      end
      
      def terminate_command
        t = Thread.new { loop { STDOUT.print('.'); STDOUT.flush; sleep(1) } }
        if @server.stop_all
          t.kill; STDOUT.puts
          puts 'Stopped all watches'
        else
          t.kill; STDOUT.puts
          puts 'Could not stop all watches within 10 seconds'
        end
        
        begin
          @server.terminate
          abort 'Could not stop god'
        rescue DRb::DRbConnError
          puts 'Stopped god'
        end
      end
      
      def check_command
        Thread.new do
          begin
            event_system = God::EventHandler.event_system
            puts "using event system: #{event_system}"
            
            if God::EventHandler.loaded?
              puts "starting event handler"
              God::EventHandler.start
            else
              puts "[fail] event system did not load"
              exit(1)
            end
            
            puts 'forking off new process'
            
            pid = fork do
              loop { sleep(1) }
            end
            
            puts "forked process with pid = #{pid}"
            
            God::EventHandler.register(pid, :proc_exit) do
              puts "[ok] process exit event received"
              exit!(0)
            end
            
            sleep(1)
            
            puts "killing process"
            
            ::Process.kill('KILL', pid)
          rescue => e
            puts e.message
            puts e.backtrace.join("\n")
          end
        end
        
        sleep(2)
        
        puts "[fail] never received process exit event"
        exit(1)
      end
      
      def lifecycle_command
        # get the name of the watch/group
        name = @args[1]
        
        puts "Sending '#{@command}' command"
        
        t = Thread.new { loop { sleep(1); STDOUT.print('.'); STDOUT.flush; sleep(1) } }
        
        # send @command
        watches = @server.control(name, @command)
        
        # output response
        t.kill; STDOUT.puts
        unless watches.empty?
          puts 'The following watches were affected:'
          watches.each do |w|
            puts '  ' + w
          end
        else
          puts 'No matching task or group'
        end
      end
    end # Command
    
  end
end