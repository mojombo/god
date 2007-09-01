require 'fileutils'

module God
  class Process
    WRITES_PID = [:start, :restart]
    
    attr_accessor :name, :uid, :gid, :log, :start, :stop, :restart
    
    def initialize(options={})
      options.each do |k,v|
        send("#{k}=", v)
      end
      
      @tracking_pid = false
    end
    
    def valid?
      # determine if we're tracking pid or not
      self.pid_file
      
      valid = true
      
      # a name must be specified
      if self.name.nil?
        valid = false
        puts "No name was specified"
      end
      
      # a start command must be specified
      if self.start.nil?
        valid = false
        puts "No start command was specified"
      end
      
      # self-daemonizing processes must specify a stop command
      if !@tracking_pid && self.stop.nil?
        valid = false
        puts "No stop command was specified"
      end
      
      # self-daemonizing processes cannot specify log
      if !@tracking_pid && self.log
        valid = false
        puts "Self-daemonizing processes cannot specify a log file"
      end
      
      # uid must exist if specified
      if self.uid
        begin
          Etc.getpwnam(self.uid)
        rescue ArgumentError
          valid = false
          puts "UID for '#{self.uid}' does not exist"
        end
      end
      
      # gid must exist if specified
      if self.gid
        begin
          Etc.getgrnam(self.gid)
        rescue ArgumentError
          valid = false
          puts "GID for '#{self.gid}' does not exist"
        end
      end
      
      valid
    end
    
    # DON'T USE THIS INTERNALLY. Use the instance variable. -- Kev
    # No really, trust me. Use the instance variable.
    def pid_file=(value)
      @tracking_pid = false
      @pid_file = value
    end
    
    def pid_file
      if @pid_file.nil?
        @tracking_pid = true
        @pid_file = default_pid_file
      end
      @pid_file
    end
    
    def start!
      call_action(:start)
    end
    
    def stop!
      call_action(:stop)
    end
    
    def restart!
      call_action(:restart)
    end
    
    def call_action(action)
      command = send(action)
      
      if action == :stop && command.nil?
        # command = "kill -9 `cat #{self.pid_file}`"
        pid = File.read(self.pid_file).strip.to_i
        name = self.name
        # log_file = self.log
        command = lambda do
          # File.open(log_file, 'a') do |logger|
          #   logger.puts "god stop [" + Time.now.strftime("%Y-%m-%d %H:%M:%S") + "] lambda killer"
          #   logger.flush
            
            puts "#{self.name} stop: default lambda killer"
            
            ::Process.kill('HUP', pid) rescue nil

            # Poll to see if it's dead
            5.times do
              begin
                ::Process.kill(0, pid)
              rescue Errno::ESRCH
                # It died. Good.
                return
              end

              sleep 1
            end

            ::Process.kill('KILL', pid) rescue nil
          # end
        end
      end
            
      if command.kind_of?(String)
        # Make pid directory
        unless test(?d, God.pid_file_directory)
          begin
            FileUtils.mkdir_p(God.pid_file_directory)
          rescue Errno::EACCES => e
            abort "Failed to create pid file directory: #{e.message}"
          end
        end
        
        unless test(?w, God.pid_file_directory)
          abort "The pid file directory (#{God.pid_file_directory}) is not writable by #{Etc.getlogin}"
        end
        
        # string command
        # fork/exec to setuid/gid
        r, w = IO.pipe
        opid = fork do
          STDOUT.reopen(w)
          r.close
          pid = fork do
            ::Process.setsid
            ::Process::Sys.setgid(Etc.getgrnam(self.gid).gid) if self.gid
            ::Process::Sys.setuid(Etc.getpwnam(self.uid).uid) if self.uid
            Dir.chdir "/"
            $0 = command
            STDIN.reopen "/dev/null"
            if self.log
              STDOUT.reopen self.log, "a"
            else
              STDOUT.reopen "/dev/null", "a"
            end
            STDERR.reopen STDOUT
            
            # STDOUT.puts "god #{action} [" + Time.now.strftime("%Y-%m-%d %H:%M:%S") + "] " + command
            # STDOUT.flush
            
            exec command unless command.empty?
          end
          puts pid.to_s
        end
        
        ::Process.waitpid(opid, 0)
        w.close
        pid = r.gets.chomp
        
        if @tracking_pid or (@pid_file.nil? and WRITES_PID.include?(action))
          File.open(default_pid_file, 'w') do |f|
            f.write pid
          end
          
          @tracking_pid = true
          @pid_file = default_pid_file
        end
        
      elsif command.kind_of?(Proc)
        # lambda command
        command.call
      else
        raise NotImplementedError
      end
    end
    
    def default_pid_file
      File.join(God.pid_file_directory, "#{self.name}.pid")
    end
  end
end
