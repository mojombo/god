require 'fileutils'

module God
  class Process
    WRITES_PID = [:start, :restart]
    
    attr_accessor :name, :uid, :gid, :log, :start, :stop, :restart
    
    def initialize
      self.log = '/dev/null'
      
      @pid_file = nil
      @tracking_pid = true
      @user_log = false
    end
    
    def alive?
      begin
        pid = File.read(self.pid_file).strip.to_i
        System::Process.new(pid).exists?
      rescue Errno::ENOENT
        false
      end
    end
    
    def file_writable?(file)
      pid = fork do
        ::Process::Sys.setgid(Etc.getgrnam(self.gid).gid) if self.gid
        ::Process::Sys.setuid(Etc.getpwnam(self.uid).uid) if self.uid
        
        File.writable?(file) ? exit(0) : exit(1)
      end
      
      wpid, status = ::Process.waitpid2(pid)
      status.exitstatus == 0 ? true : false
    end
    
    def valid?
      # determine if we're tracking pid or not
      self.pid_file
      
      valid = true
      
      # a start command must be specified
      if self.start.nil?
        valid = false
        applog(self, :error, "No start command was specified")
      end
      
      # self-daemonizing processes must specify a stop command
      if !@tracking_pid && self.stop.nil?
        valid = false
        applog(self, :error, "No stop command was specified")
      end
      
      # uid must exist if specified
      if self.uid
        begin
          Etc.getpwnam(self.uid)
        rescue ArgumentError
          valid = false
          applog(self, :error, "UID for '#{self.uid}' does not exist")
        end
      end
      
      # gid must exist if specified
      if self.gid
        begin
          Etc.getgrnam(self.gid)
        rescue ArgumentError
          valid = false
          applog(self, :error, "GID for '#{self.gid}' does not exist")
        end
      end
      
      # pid dir must exist if specified
      if !@tracking_pid && !File.exist?(File.dirname(self.pid_file))
        valid = false
        applog(self, :error, "PID file directory '#{File.dirname(self.pid_file)}' does not exist")
      end
      
      # pid dir must be writable if specified
      if !@tracking_pid && File.exist?(File.dirname(self.pid_file)) && !file_writable?(File.dirname(self.pid_file))
        valid = false
        applog(self, :error, "PID file directory '#{File.dirname(self.pid_file)}' is not writable by #{self.uid || Etc.getlogin}")
      end
      
      # log dir must exist
      if !File.exist?(File.dirname(self.log))
        valid = false
        applog(self, :error, "Log directory '#{File.dirname(self.log)}' does not exist")
      end
      
      # log file or dir must be writable
      if File.exist?(self.log)
        unless file_writable?(self.log)
          valid = false
          applog(self, :error, "Log file '#{self.log}' exists but is not writable by #{self.uid || Etc.getlogin}")
        end
      else
        unless file_writable?(File.dirname(self.log))
          valid = false
          applog(self, :error, "Log directory '#{File.dirname(self.log)}' is not writable by #{self.uid || Etc.getlogin}")
        end
      end
      
      valid
    end
    
    # DON'T USE THIS INTERNALLY. Use the instance variable. -- Kev
    # No really, trust me. Use the instance variable.
    def pid_file=(value)
      # if value is nil, do the right thing
      if value
        @tracking_pid = false
      else
        @tracking_pid = true
      end
      
      @pid_file = value
    end
    
    def pid_file
      @pid_file ||= default_pid_file
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
    
    def spawn(command)
      fork do
        ::Process.setsid
        ::Process::Sys.setgid(Etc.getgrnam(self.gid).gid) if self.gid
        ::Process::Sys.setuid(Etc.getpwnam(self.uid).uid) if self.uid
        Dir.chdir "/"
        $0 = command
        STDIN.reopen "/dev/null"
        STDOUT.reopen self.log, "a"
        STDERR.reopen STDOUT
        
        # close any other file descriptors
        3.upto(256){|fd| IO::new(fd).close rescue nil}
        
        exec command unless command.empty?
      end
    end
    
    def call_action(action)
      command = send(action)
      
      if action == :stop && command.nil?
        pid = File.read(self.pid_file).strip.to_i
        name = self.name
        command = lambda do
          applog(self, :info, "#{self.name} stop: default lambda killer")
          
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
        pid = nil
        
        if @tracking_pid
          # double fork god-daemonized processes
          # we don't want to wait for them to finish
          r, w = IO.pipe
          begin
            opid = fork do
              STDOUT.reopen(w)
              r.close
              pid = self.spawn(command)
              puts pid.to_s # send pid back to forker
            end
            
            ::Process.waitpid(opid, 0)
            w.close
            pid = r.gets.chomp
          ensure
            # make sure the file descriptors get closed no matter what
            r.close rescue nil
            w.close rescue nil
          end
        else
          # single fork self-daemonizing processes
          # we want to wait for them to finish
          pid = self.spawn(command)
          ::Process.waitpid(pid, 0)
        end
        
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
