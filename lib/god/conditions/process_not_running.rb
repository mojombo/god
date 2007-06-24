module God
  module Conditions
    
    class ProcessNotRunning < Condition
      attr_accessor :pid_file
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute for :process_not_running") if self.pid_file.nil?
        valid
      end
    
      def test
        return false unless File.exist?(self.pid_file)
        
        pid = File.open(self.pid_file).read.strip
        System::Process.new(pid).exists?
      end
    end
    
  end
end