module God
  
  class Trigger
    
    class << self
      attr_accessor :triggers
    end
    
    @triggers = []
    @mutex = Mutex.new
    
    def self.register(condition)
      @mutex.synchronize do
        self.triggers << condition
      end
    end
    
    def self.deregister(condition)
      @mutex.synchronize do
        self.triggers.delete(condition)
      end
    end
    
    def self.broadcast(message, payload)
      @mutex.synchronize do
        self.triggers.each do |t|
          t.process(message, payload)
        end
      end
    end
    
  end
  
end