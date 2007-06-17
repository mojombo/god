module God
  module Conditions
    
    class MemoryUsage < ProcessCondition
      attr_accessor :above, :times
    
      def initialize
        super
        self.above = nil
        self.times = [1, 1]
      end
      
      def prepare
        p self.times.class
        
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end
        
        @timeline = Timeline.new(self.times[1])
      end
    
      def valid?
        valid = super
        valid = complain("You must specify the 'above' attribute for :memory_usage") if self.above.nil?
        valid
      end
    
      def test
        return false unless super
        pid = File.open(self.pid_file).read.strip
        process = System::Process.new(pid)
        @timeline.push(process.memory)
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