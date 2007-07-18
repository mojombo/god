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
      @@actions[pid][event].call
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