module God
  class EventHandler
    @@actions = {}
    @@handler = nil
    
    def self.handler=(value)
      @@handler = value
    end
    
    def self.register(pid, event, &block)
      @@handler.register_event(pid, event)
      @@actions[pid][event] = block
    end
    
    def self.call(id, proc)
      @@actions[id][proc].call
    end
    
    def self.run_event_thread
      Thread.new do
        loop do
          @@handler.handle_events
        end
      end
    end
    
  end
end