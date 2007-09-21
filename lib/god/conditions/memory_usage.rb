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
        valid &= complain("Attribute 'pid_file' must be specified", self) if self.watch.pid_file.nil?
        valid &= complain("Attribute 'above' must be specified", self) if self.above.nil?
        valid
      end
    
      def test
        return false unless File.exist?(self.watch.pid_file)
        
        pid = File.read(self.watch.pid_file).strip
        process = System::Process.new(pid)
        @timeline.push(process.memory)
        
        history = "[" + @timeline.map { |x| "#{x}kb" }.join(", ") + "]"
        
        if @timeline.select { |x| x > self.above }.size >= self.times.first
          @timeline.clear
          self.info = "memory out of bounds #{history}"
          return true
        else
          self.info = "memory within bounds #{history}"
          return false
        end
      end
    end
    
  end
end