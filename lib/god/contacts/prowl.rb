# Send a notice to Prowl (http://prowl.weks.net/).
#
# apikey - The String API key.

CONTACT_DEPS[:prowl] = ['prowly']
CONTACT_DEPS[:prowl].each do |d|
  require d
end

module God
  module Contacts
    class Prowl < Contact

      class << self
        attr_accessor :apikey
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'apikey' must be specified", self) if self.apikey.nil?
        valid
      end

      attr_accessor :apikey

      def notify(message, time, priority, category, host)
        result = Prowly.notify do |n|
          n.apikey      = arg(:apikey)
          n.priority    = map_priority(priority.to_i)
          n.application = category || "God"
          n.event       = "on " + host.to_s
          n.description = message.to_s + " at " + time.to_s
        end

        if result.succeeded?
          self.info = "sent prowl notification to #{self.name}"
        else
          self.info = "failed to send prowl notification to #{self.name}: #{result.message}"
        end
      rescue Object => e
        applog(nil, :info, "failed to send prowl notification to #{self.name}: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end

      def map_priority(priority)
        case priority
           when 1 then Prowly::Notification::Priority::EMERGENCY
           when 2 then Prowly::Notification::Priority::HIGH
           when 3 then Prowly::Notification::Priority::NORMAL
           when 4 then Prowly::Notification::Priority::MODERATE
           when 5 then Prowly::Notification::Priority::VERY_LOW
           else Prowly::Notification::Priority::NORMAL
        end
      end
    end
  end
end
