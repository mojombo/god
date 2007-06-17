module God
  module Conditions
    
    class ProcessNotRunning < ProcessCondition
      def test
        return false unless super
        pid = File.open(self.pid_file).read.strip
        process_running?(pid)
      end
        
      private
    
      def process_running?(pid)
        cmd_name = RUBY_PLATFORM =~ /solaris/i ? "args" : "command"
        ps_output = `ps -o #{cmd_name}= -p #{pid}`
        !ps_output.strip.empty?
      end 
    end
    
  end
end