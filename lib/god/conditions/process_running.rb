module God
  module Conditions
    
    class ProcessRunning < PollCondition
      attr_accessor :running
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute on the Watch for :process_running") if self.watch.pid_file.nil?
        valid &= complain("You must specify the 'running' attribute for :process_running") if self.running.nil?
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