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
        return !self.running unless File.exist?(self.watch.pid_file)
        
        pid = File.read(self.watch.pid_file).strip
        active = System::Process.new(pid).exists?
        
        (self.running && active) || (!self.running && !active)
      end
    end
    
  end
end