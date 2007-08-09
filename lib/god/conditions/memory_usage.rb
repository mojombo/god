module God
  module Conditions
    
    class MemoryUsage < PollCondition
      attr_accessor :above, :times
    
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
        valid &= complain("You must specify the 'pid_file' attribute on the Watch for :memory_usage") if self.watch.pid_file.nil?
        valid &= complain("You must specify the 'above' attribute for :memory_usage") if self.above.nil?
        valid
      end
    
      def test
        return false unless File.exist?(self.watch.pid_file)
        
        pid = File.read(self.watch.pid_file).strip
        process = System::Process.new(pid)
        @timeline.push(process.memory)
        if @timeline.select { |x| x > self.above }.size >= self.times.first
          @timeline.clear
          return true
        else
          return false
        end
      end
    end
    
  end
end