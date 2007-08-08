require 'fileutils'

module God
  class Process
    WRITES_PID = [:start, :restart]
    
    attr_accessor :name, :uid, :gid, :start, :stop, :restart
    
    def initialize(options={})
      options.each do |k,v|
        send("#{k}=", v)
      end
      
      @tracking_pid = false
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
      if command.kind_of?(String)
        # Make pid directory
        unless test(?d, God.pid_file_directory)
          begin
            FileUtils.mkdir_p(God.pid_file_directory)
          rescue Errno::EACCES => e
            abort"Failed to create pid file directory: #{e.message}"
          end
        end
        
        unless test(?w, God.pid_file_directory)
          abort "The pid file directory (#{God.pid_file_directory}) is not writable by #{Etc.getlogin}"
        end
        
        # string command
        # fork/exec to setuid/gid
        pid = fork {
          ::Process.setsid
          ::Process::Sys.setgid(Etc.getgrnam(self.gid).gid) if self.gid
          ::Process::Sys.setuid(Etc.getpwnam(self.uid).uid) if self.uid
          Dir.chdir "/"
          $0 = command
          STDIN.reopen "/dev/null"
          STDOUT.reopen "/dev/null", "a"
          STDERR.reopen STDOUT
          exec command
        }
        
        ::Process.detach pid
        
        if @tracking_pid or (self.pid_file.nil? and WRITES_PID.include?(action))
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
