require 'fileutils'

module God
  class Process
    WRITES_PID = [:start, :restart]
    
    attr_accessor :name, :uid, :gid, :start, :stop, :restart, :pid_file
    
    def initialize(options={})
      options.each do |k,v|
        send("#{k}=", v)
      end
      
      @tracking_pid = false
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
        # string command
        # fork/exec to setuid/gid
        pid = fork {
          Process::Sys.setgid(Etc.getgrnam(self.gid).gid) if self.gid
          Process::Sys.setuid(Etc.getpwnam(self.uid).uid) if self.uid
          $0 = command
          exec command
        }
        
        if @tracking_pid or (self.pid_file.nil? and WRITES_PID.include?(action))
          unless test(?d, God.pid_file_directory)
            FileUtils.mkdir_p(God.pid_file_directory)
          end
          File.open(default_pid_file, 'w') do |f|
            f.write pid
          end
          
          @tracking_pid = true
          self.pid_file = default_pid_file
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
