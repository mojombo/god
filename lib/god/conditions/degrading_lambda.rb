module God
  module Conditions
    
    # This condition degrades its interval by a factor of two for 3 tries before failing
    class DegradingLambda < PollCondition
      attr_accessor :lambda
      
      def initialize
        super
        @tries = 0
      end
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'lambda' attribute for :degrading_lambda") if self.lambda.nil?
        valid
      end

      def test
        puts "Calling test. Interval at #{self.interval}"
        @original_interval ||= self.interval
        unless pass?
          return true if @tries == 2
          self.interval = self.interval / 2.0
          @tries += 1
        else
          @tries = 0
          self.interval = @original_interval
        end
        false
      end
      
      private
        
        def pass?
          begin
            Timeout::timeout(@interval) {
              self.lambda.call()
            }
          rescue Timeout::Error
            false
          end
        end
    end

  end
end