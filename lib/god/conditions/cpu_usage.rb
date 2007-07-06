module God
  module Conditions
    
    class CpuUsage < PollCondition
      attr_accessor :pid_file, :above, :times
    
      def initialize
        super
        self.above = nil
        self.times = [1, 1]
      end
      
      def prepare
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end
        
        @timeline = Timeline.new(self.times[1])
      end
    
      def valid?
        valid = true
        valid &= complain("You must specify the 'pid_file' attribute for :memory_usage") if self.pid_file.nil?
        valid &= complain("You must specify the 'above' attribute for :memory_usage") if self.above.nil?
        valid
      end
    
      def test
        return false unless File.exist?(self.pid_file)
        
        pid = File.open(self.pid_file).read.strip
        process = System::Process.new(pid)
        @timeline.push(process.percent_cpu)
        if @timeline.select { |x| x > self.above }.size < self.times.first
          return true
        else
          @timeline.clear
          return false
        end
      end
    end
    
  end
end