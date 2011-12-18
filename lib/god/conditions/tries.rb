module God
  module Conditions

    class Tries < PollCondition
      attr_accessor :times, :within

      def prepare
        @timeline = Timeline.new(self.times)
      end

      def reset
        @timeline.clear
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

        if within
          history = "[#{@timeline.size}/#{self.times} within #{(@timeline.last - @timeline.first).to_i}s]"
        else
          history = "[#{@timeline.size}/#{self.times}]"
        end

        if concensus && duration
          self.info = "tries exceeded #{history}"
          return true
        else
          self.info = "tries within bounds #{history}"
          return false
        end
      end
    end

  end
end
