module God
  class EventHandler
    @@actions = {}
    
    case RUBY_PLATFORM
    when /darwin/i, /bsd/i
      require 'kqueue_handler'
      @@handler = KQueueHandler
    else
      raise NotImplementedError, "Platform not supported for EventHandler"
    end
    
    def self.register(pid, event, &block)
      @@actions[pid] = block
      @@handler.register_event(pid, event)
    end
    
    def self.call(id)
      @@actions[id].call
    end
    
    def self.run_event_thread
      Thread.new do
        loop do
          puts "Running the event thread"
          @@handler.handle_events
        end
      end
    end
    
  end
end