module God
  
  class Timeline < Array
    # Instantiate a new Timeline
    #   +max_size+ is the maximum size to which the timeline should grow
    #
    # Returns Timeline
    def initialize(max_size)
      super(max_size)
      @max_size = max_size
      @i = 0
    end
    
    # Push a value onto the Timeline
    #   +val+ is the value to push
    #
    # Returns Timeline
    def push(val)
      self[@i] = val
      @i += 1
      @i = 0 if @i == @max_size
    end
    
    alias_method :<<, :push
  end
  
end