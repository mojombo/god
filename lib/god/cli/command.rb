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
        DRb.start_service("druby://127.0.0.1:0")
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
        if %w{load status signal log quit terminate}.include?(@command)
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
        exitcode = 0
        statuses = @server.status
        groups = {}
        statuses.each do |name, status|
          g = status[:group] || ''
          groups[g] ||= {}
          groups[g][name] = status
        end

        if item = @args[1]
          if single = statuses[item]
            # specified task (0 -> up, 1 -> unmonitored, 2 -> other)
            puts CLI::Command::process_state(item, single)
            exitcode = state == :up ? 0 : (state == :unmonitored ? 1 : 2)
          elsif groups[item]
            # specified group (0 -> up, N -> other)
            puts "#{item}:"
            width = groups[item].keys.map(&:size).max
            groups[item].keys.sort.each do |name|
              puts CLI::Command::process_state(name, groups[item][name], width)
              exitcode += 1 unless state == :up
            end
          else
            puts "Task or Group '#{item}' not found."
            exit(1)
          end
        else
          # show all groups and watches
          groups.keys.sort.each do |group|
            puts "#{group}:" unless group.empty?
            width = groups[group].keys.map(&:size).max
            groups[group].keys.sort.each do |name|
              print "  " unless group.empty?
              puts CLI::Command::process_state(name, groups[group][name], width)
            end
          end
        end

        exit(exitcode)
      end

      def signal_command
        # get the name of the watch/group
        name = @args[1]
        signal = @args[2]

        puts "Sending signal '#{signal}' to '#{name}'"

        t = Thread.new { loop { sleep(1); STDOUT.print('.'); STDOUT.flush; sleep(1) } }

        watches = @server.signal(name, signal)

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

      def log_command
        begin
          Signal.trap('INT') { exit }
          name = @args[1]

          unless name
            puts "You must specify a Task or Group name"
            exit!
          end

          puts "Please wait..."
          t = Time.at(0)
          loop do
            print @server.running_log(name, t)
            t = Time.now
            sleep 0.25
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
          puts "Could not stop all watches within #{@server.terminate_timeout} seconds"
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
            ::Process.waitpid(pid)
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

      class << self
        # See the source code of (procps-3.2.8/ps/output.c::pr_etime)
        # See also ps(1). The format of etime: [[dd-]hh:]mm:ss.
        def seconds_to_text(t)
          ss = t%60 ; t /= 60 ; mm = t%60 ; t /= 60 ;
          hh = t%24 ; t /= 24 ; dd = t
          st = ""
          st << sprintf("%u-", dd) unless dd.to_i.zero?
          st << sprintf("%02u:", hh) unless dd.to_i.zero? and hh.to_i.zero?
          st << sprintf("%02u:%02u", mm, ss)
          st
        end

        # FIXME: God should handle the status of process
        def process_state(name, obj, width = 0)
          state = obj[:state]
          st = []
          st << sprintf("%#{width}s: %s", name, state)
          if state == :up
            pid = obj[:pid]
            st << sprintf("pid %5d", pid)
            spid = System::Process.new(pid)
            if spid.exists?
              st << "uptime #{CLI::Command::seconds_to_text(spid.uptime)}"
            else
              st << "non alive"
            end
          end
          st.join(", ")
        end
      end
    end # Command

  end
end
