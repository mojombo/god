module God
  module Conditions
    
    class Timeline < Array
      def initialize(max_size)
        super()
        @max_size = max_size
      end
      
      def push(val)
        unshift(val)
        pop if size > @max_size
      end
    end
    
  end
end