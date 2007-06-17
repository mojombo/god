module God
  
  class ProcessCondition < Condition
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
      File.exist?(self.pid_file)
    end
  
    def before_start
      if self.clean
        File.delete(self.pid_file) rescue nil
      end
    end
  end
  
end