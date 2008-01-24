module God
  
  class Timeline < Array
    # Instantiate a new Timeline
    #   +max_size+ is the maximum size to which the timeline should grow
    #
    # Returns Timeline
    def initialize(max_size)
      super()
      @max_size = max_size
    end
    
    # Push a value onto the Timeline
    #   +val+ is the value to push
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
    #
    # Returns Timeline
    def push(val)
      self.concat([val])
      shift if size > @max_size
    end
    
    # Push a value onto the timeline
    #   +val+ is the value to push
    #
    # Returns Timeline
    def <<(val)
      push(val)
    end
  end
  
end