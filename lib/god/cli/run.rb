module God
  module CLI

    class Run
      def initialize(options)
        @options = options

        dispatch
      end

      def dispatch
        # have at_exit start god
        $run = true

        if @options[:syslog]
          require 'god/sys_logger'
        end

        # run
        if @options[:daemonize]
          run_daemonized
        else
          run_in_front
        end
      end

      def attach
        process = System::Process.new(@options[:attach])
        Thread.new do
          loop do
            unless process.exists?
              applog(nil, :info, "Going down because attached process #{@options[:attach]} exited")
              exit!
            end
            sleep 5
          end
        end
      end

      def default_run
        # make sure we have STDIN/STDOUT redirected immediately
        setup_logging

        # start attached pid watcher if necessary
        if @options[:attach]
          self.attach
        end

        if @options[:port]
          God.port = @options[:port]
        end

        if @options[:events]
          God::EventHandler.load
        end

        # set log level, defaults to WARN
        if @options[:log_level]
          God.log_level = @options[:log_level]
        else
          God.log_level = @options[:daemonize] ? :warn : :info
        end

        if @options[:config]
          if !@options[:config].include?('*') && !File.exist?(@options[:config])
            abort "File not found: #{@options[:config]}"
          end

          # start the event handler
          God::EventHandler.start if God::EventHandler.loaded?

          load_config @options[:config]
        end
        setup_logging
      end

      def run_in_front
        require 'god'

        default_run
      end

      def run_daemonized
        # trap and ignore SIGHUP
        Signal.trap('HUP') {}

        pid = fork do
          begin
            require 'god'

            # set pid if requested
            if @options[:pid] # and as deamon
              God.pid = @options[:pid]
            end

            default_run

            unless God::EventHandler.loaded?
              puts
              puts "***********************************************************************"
              puts "*"
              puts "* Event conditions are not available for your installation of god."
              puts "* You may still use and write custom conditions using the poll system"
              puts "*"
              puts "***********************************************************************"
              puts
            end

          rescue => e
            puts e.message
            puts e.backtrace.join("\n")
            abort "There was a fatal system error while starting god (see above)"
          end
        end

        if @options[:pid]
          File.open(@options[:pid], 'w') { |f| f.write pid }
        end

        ::Process.detach pid

        exit
      end

      def setup_logging
        log_file = God.log_file
        log_file = File.expand_path(@options[:log]) if @options[:log]
        log_file = "/dev/null" if !log_file && @options[:daemonize]
        if log_file
          puts "Sending output to log file: #{log_file}" unless @options[:daemonize]

          # reset file descriptors
          STDIN.reopen "/dev/null"
          STDOUT.reopen(log_file, "a")
          STDERR.reopen STDOUT
          STDOUT.sync = true
        end
      end

      def load_config(config)
        files = File.directory?(config) ? Dir['**/*.god'] : Dir[config]
        abort "No files could be found" if files.empty?
        files.each do |god_file|
          unless load_god_file(god_file)
            abort "File '#{god_file}' could not be loaded"
          end
        end
      end

      def load_god_file(god_file)
        applog(nil, :info, "Loading #{god_file}")
        load File.expand_path(god_file)
        true
      rescue Exception => e
        if e.instance_of?(SystemExit)
          raise
        else
          puts "There was an error in #{god_file}"
          puts "\t" + e.message
          puts "\t" + e.backtrace.join("\n\t")
          false
        end
      end

    end # Run

  end
end
