module God
    
    class Timeline < Array
      def initialize(max_size)
        super()
        @max_size = max_size
      end
      
      # Push a value onto the Timeline
      # 
      # Implementation explanation:
      # A performance optimization appears here to speed up the push time.
      # In essence, the code does this:
      #
      #   def push(val)
      #     super(val)
      #     shift if size > @max_size
      #   end
      #
      # But that's super slow due to the shift, so we resort to reverse! and pop
      # which gives us a 2x speedup with 100 elements and a 6x speedup with 1000
      def push(val)
        if (size + 1) > @max_size
          reverse!
          pop
          reverse!
        end
        super(val)
      end
      
      def <<(val)
        push(val)
      end
    end
    
end