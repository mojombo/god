module God
  
  class Timeline
    extend Forwardable
    def_delegators :@storage, :clear, :size, :first, :last, :[], :to_ary, :to_a
    
    # Instantiate a new Timeline
    #   +max_size+ is the maximum size to which the timeline should grow
    #
    # Returns Timeline
    def initialize(max_size)
      @storage = []
      @max_size = max_size
    end
    
    # Push a value onto the Timeline
    #   +val+ is the value to push
    def push(val)
      @storage.concat([val])
      @storage = @storage[1..-1] if @storage.size > @max_size
      # @storage.shift if @storage.size > @max_size
    end
    
    alias_method :<<, :push
    
    # # Push a value onto the timeline
    # #   +val+ is the value to push
    # #
    # # Returns Timeline
    # def <<(val)
    #   push(val)
    # end
  end
  
end