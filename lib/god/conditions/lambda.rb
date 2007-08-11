module God
   module Conditions
     
     class Lambda < PollCondition
       attr_accessor :lambda

       def valid?
         valid = true
         valid &= complain("You must specify the 'lambda' attribute for :custom") if self.lambda.nil?
         valid
       end

       def test
         return self.lambda.call()
       end
     end

   end
end