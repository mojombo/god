module God
  module Conditions
    
    class Tries < PollCondition
      attr_accessor :times, :within
      
      def prepare
        @timeline = Timeline.new(self.times)
      end
    
      def valid?
        valid = true
        valid &= complain("Attribute 'times' must be specified", self) if self.times.nil?
        valid
      end
    
      def test
        @timeline << Time.now
        
        concensus = (@timeline.size == self.times)
        duration = self.within.nil? || (@timeline.last - @timeline.first) < self.within
        
        if concensus && duration
          @timeline.clear if within.nil?
          return true
        else
          return false
        end
      end
    end
    
  end
end