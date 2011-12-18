require 'kqueue_handler_ext'

module God
  class KQueueHandler
    EVENT_SYSTEM = "kqueue"

    def self.register_process(pid, events)
      monitor_process(pid, events_mask(events))
    end

    def self.events_mask(events)
      events.inject(0) do |mask, event|
        mask |= event_mask(event)
      end
    end
  end
end
