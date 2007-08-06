module God
  class Process
    attr_accessor :name, :uid, :gid, :start, :stop, :restart, :pidfile
    
    def initialize(options={})
      options.each do |k,v|
        send("#{k}=", v)
      end
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
        fork {
          Process::Sys.setgid(Etc.getgrnam(self.gid).gid) if self.gid
          Process::Sys.setuid(Etc.getpwnam(self.uid).uid) if self.uid
          $0 = command
          exec command
        }
      elsif command.kind_of?(Proc)
        # lambda command
        command.call
      else
        raise NotImplementedError
      end
    end
  end
end
