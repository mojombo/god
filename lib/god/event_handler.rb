module God
  class EventHandler
    @@actions = {}
    @@handler = nil
    @@loaded = false
    
    def self.loaded?
      @@loaded
    end
    
    def self.event_system
      @@handler::EVENT_SYSTEM
    end
    
    def self.load
      begin
        case RUBY_PLATFORM
        when /darwin/i, /bsd/i
          require 'god/event_handlers/kqueue_handler'
          @@handler = KQueueHandler
        when /linux/i
          require 'god/event_handlers/netlink_handler'
          @@handler = NetlinkHandler
        else
          raise NotImplementedError, "Platform not supported for EventHandler"
        end
        @@loaded = true
      rescue Exception
        require 'god/event_handlers/dummy_handler'
        @@handler = DummyHandler
        @@loaded = false
      end
    end
    
    def self.register(pid, event, &block)
      @@actions[pid] ||= {}
      @@actions[pid][event] = block
      @@handler.register_process(pid, @@actions[pid].keys)
    end
    
    def self.deregister(pid, event=nil)
      if watching_pid? pid
        if event.nil?
          @@actions.delete(pid)
          @@handler.register_process(pid, []) if system("kill -0 #{pid} &> /dev/null")
        else
          @@actions[pid].delete(event)
          @@handler.register_process(pid, @@actions[pid].keys) if system("kill -0 #{pid} &> /dev/null")
        end
      end
    end
    
    def self.call(pid, event)
      @@actions[pid][event].call if watching_pid?(pid) && @@actions[pid][event]
    end
    
    def self.watching_pid?(pid)
      @@actions[pid]
    end
    
    def self.start
      Thread.new do
        loop do
          @@handler.handle_events
        end
      end
    end
    
  end
end