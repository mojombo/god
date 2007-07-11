module God
  class EventHandler
    @@actions = {}
    @@handler = nil
    
    def self.handler=(value)
      @@handler = value
    end
    
    def self.register(pid, event, &block)
      @@actions[pid] ||= {}
      @@actions[pid][event] = block
      @@handler.register_process(pid, events_mask(pid))
    end
    
    def self.call(pid, event)
      @@actions[pid][event].call
    end
    
    def self.run_event_thread
      Thread.new do
        loop do
          @@handler.handle_events
        end
      end
    end
    
    # I'm not entirely happy with this. I'm not sure if this will
    # be netlink friendly when we write the linux connector
    #  -- Kev
    def self.events_mask(pid)
      @@actions[pid].keys.inject(0) do |mask, event|
        mask |= @@handler.event_mask(event)
      end
    end
  end
end