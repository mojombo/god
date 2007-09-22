require 'fileutils'

module God
  class Process
    WRITES_PID = [:start, :restart]
    
    attr_accessor :name, :uid, :gid, :log, :start, :stop, :restart
    
    def initialize
      self.log = '/dev/null'
      
      @pid_file = nil
      @tracking_pid = false
    end
    
    def alive?
      begin
        pid = File.read(self.pid_file).strip.to_i
        System::Process.new(pid).exists?
      rescue Errno::ENOENT
        false
      end
    end
    
    def valid?
      # determine if we're tracking pid or not
      self.pid_file
      
      valid = true
      
      # a start command must be specified
      if self.start.nil?
        valid = false
        LOG.log(self, :error, "No start command was specified")
      end
      
      # self-daemonizing processes must specify a stop command
      if !@tracking_pid && self.stop.nil?
        valid = false
        LOG.log(self, :error, "No stop command was specified")
      end
      
      # uid must exist if specified
      if self.uid
        begin
          Etc.getpwnam(self.uid)
        rescue ArgumentError
          valid = false
          LOG.log(self, :error, "UID for '#{self.uid}' does not exist")
        end
      end
      
      # gid must exist if specified
      if self.gid
        begin
          Etc.getgrnam(self.gid)
        rescue ArgumentError
          valid = false
          LOG.log(self, :error, "GID for '#{self.gid}' does not exist")
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
        pid = File.read(self.pid_file).strip.to_i
        name = self.name
        command = lambda do
          LOG.log(self, :info, "#{self.name} stop: default lambda killer")
          
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
        end
      end
            
      if command.kind_of?(String)
        # string command
        if @tracking_pid
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
              STDOUT.reopen self.log, "a"
              STDERR.reopen STDOUT
              
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
        else
          orig_stdout = STDOUT.dup
          orig_stderr = STDERR.dup
          
          STDOUT.reopen self.log, "a"
          STDERR.reopen STDOUT
          
          system(command)
          
          STDOUT.reopen orig_stdout
          STDERR.reopen orig_stderr
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
