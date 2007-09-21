module God
  module Conditions
    
    class ProcessRunning < PollCondition
      attr_accessor :running
      
      def valid?
        valid = true
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.watch.pid_file.nil?
        valid &= complain("Attribute 'running' must be specified", self) if self.running.nil?
        valid
      end
    
      def test
        self.info = []
        
        unless File.exist?(self.watch.pid_file)
          self.info << "#{self.watch.name} #{self.class.name}: no such pid file: #{self.watch.pid_file}"
          return !self.running
        end
        
        pid = File.read(self.watch.pid_file).strip
        active = System::Process.new(pid).exists?
        
        if (self.running && active)
          self.info << "process is running"
          true
        elsif (!self.running && !active)
          self.info << "process is not running"
          true
        else
          if self.running
            self.info << "process is not running"
          else
            self.info << "process is running"
          end
          false
        end
      end
    end
    
  end
end