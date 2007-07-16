require 'kqueue_handler_ext'

module God
  class KQueueHandler
    def self.register_process(pid, events)
      begin
        puts 'aa'
        # raise StandardError.new('faaaaaaaaaail')
        monitor_process(pid, events_mask(events))
        puts 'bb'
      rescue StandardError => e
        puts e.inspect
      end
    end
  
    def self.events_mask(events)
      events.inject(0) do |mask, event|
        mask |= event_mask(event)
      end
    end
  end
end