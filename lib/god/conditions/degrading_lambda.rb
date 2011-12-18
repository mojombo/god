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
        valid &= complain("Attribute 'lambda' must be specified", self) if self.lambda.nil?
        valid
      end

      def test
        puts "Calling test. Interval at #{self.interval}"
        @original_interval ||= self.interval
        unless pass?
          if @tries == 2
            self.info = "lambda condition was satisfied"
            return true
          end
          self.interval = self.interval / 2.0
          @tries += 1
        else
          @tries = 0
          self.interval = @original_interval
        end

        self.info = "lambda condition was not satisfied"
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
