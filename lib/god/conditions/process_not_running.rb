module God
  class ProcessNotRunning < Condition
    attr_accessor :pid_file, :clean
    
    def initialize
      self.pid_file = nil
      self.clean = true
    end
    
    def valid?
      valid = true
      valid = complain("You must specify the 'pid_file' attribute for :process_not_running") if self.pid_file.nil?
      valid
    end
    
    def test
      return false unless File.exist?(self.pid_file)
      pid = File.open(self.pid_file).read.strip
      process_running?(pid)
    end
    
    def after
      if self.clean
        File.delete(self.pid_file) rescue nil
      end
    end
    
    private
    
    def process_running?(pid)
      cmd_name = RUBY_PLATFORM =~ /solaris/i ? "args" : "command"
      ps_output = `ps -o #{cmd_name}= -p #{pid}`
      !ps_output.strip.empty?
    end 
  end
end
