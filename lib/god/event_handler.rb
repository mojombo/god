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

    def self.deregister(pid, event)
      if watching_pid? pid
        running = ::Process.kill(0, pid.to_i) rescue false
        @@actions[pid].delete(event)
        @@handler.register_process(pid, @@actions[pid].keys) if running
        @@actions.delete(pid) if @@actions[pid].empty?
      end
    end

    def self.call(pid, event, extra_data = {})
      @@actions[pid][event].call(extra_data) if watching_pid?(pid) && @@actions[pid][event]
    end

    def self.watching_pid?(pid)
      @@actions[pid]
    end

    def self.start
      Thread.new do
        loop do
          begin
            @@handler.handle_events
          rescue Exception => e
            message = format("Unhandled exception (%s): %s\n%s",
                             e.class, e.message, e.backtrace.join("\n"))
            applog(nil, :fatal, message)
          end
        end
      end

      # do a real test to make sure events are working properly
      @@loaded = self.operational?
    end

    def self.operational?
      com = [false]

      Thread.new do
        begin
          event_system = God::EventHandler.event_system

          pid = fork do
            loop { sleep(1) }
          end

          self.register(pid, :proc_exit) do
            com[0] = true
          end

          ::Process.kill('KILL', pid)
          ::Process.waitpid(pid)

          sleep(0.1)

          self.deregister(pid, :proc_exit) rescue nil
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
        end
      end.join

      sleep(0.1)

      com.first
    end

  end
end
