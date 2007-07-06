module God
  module Conditions

    class Always < PollCondition
      def test
        false
      end
    end
  
  end
end