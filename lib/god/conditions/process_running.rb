module God
  module Conditions
    
    class ProcessRunning < PollCondition
      attr_accessor :pid_file, :running
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute for :process_running") if self.pid_file.nil?
        valid &= complain("You must specify the 'running' attribute for :process_running") if self.running.nil?
        valid
      end
    
      def test
        return !self.running unless File.exist?(self.pid_file)
        
        pid = File.open(self.pid_file).read.strip
        active = System::Process.new(pid).exists?
        
        (self.running && active) || (!self.running && !active)
      end
    end
    
  end
end