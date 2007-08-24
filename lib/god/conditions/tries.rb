module God
  module Conditions
    
    class Tries < PollCondition
      attr_accessor :times
      
      def prepare
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end
        
        @timeline = Timeline.new(self.times[1])
      end
    
      def valid?
        valid = true
        valid &= complain("You must specify the 'times' attribute for :tries") if self.times.nil?
        valid
      end
    
      def test
        @timeline.push(true)
        if @timeline.select { |x| x }.size >= self.times.first
          @timeline.clear
          return true
        else
          return false
        end
      end
    end
    
  end
end