module God
    
    class Timeline < Array
      def initialize(max_size)
        super()
        @max_size = max_size
      end
      
      def push(val)
        super(val)
        shift if size > @max_size
      end
      
      def <<(val)
        push(val)
      end
    end
    
end