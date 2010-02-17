# Rafael Magaña <raf.magana@gmail.com>
# 
# For Prowl notifications you need the 'prowly' gem
#   (gem install prowly)
#
# Configure your watches like this:
#
#   God.contact(:prowl) do |c|
#     c.name      = 'georgette'
#     c.apikey    = 'ffffffffffffffffffffffffffffffffffffffff'
#     c.group     = 'developers'
#   end
#
#
#   God.contact(:prowl) do |c|
#     c.name      = 'johnny'
#     c.apikey    = 'ffffffffffffffffffffffffffffffffffffffff'
#     c.group     = 'developers'
#   end
#
#
#  Define a transition for the process running event
#
#   w.transition(:up, :start) do |on|
#     on.condition(:process_running) do |c|
#        c.running = true
#        c.notify = 'developers'
#     end
#   end

require 'prowly'

module God
  module Contacts
    class Prowl < Contact
      
      attr_accessor :apikey
      
      def valid?
        valid = true
      end

      def notify(message, time, priority, category, host)
        begin
          result = Prowly.notify do |n|
            n.apikey      = self.apikey
            n.priority    = map_priority(priority.to_i)
            n.application = category
            n.event       = "on " + host.to_s
            n.description = message.to_s + " at " + time.to_s
          end

          if result.succeeded?
            self.info = "sent prowl notification to #{self.name}"
          else
            self.info = "failed to send prowl notification to #{self.name}: #{result.message}"
          end
        end
      end
      
      private
      def map_priority(priority)
        prowl_priority = case priority
                           when 1 then Prowly::Notification::Priority::EMERGENCY
                           when 2 then Prowly::Notification::Priority::HIGH
                           when 3 then Prowly::Notification::Priority::NORMAL
                           when 4 then Prowly::Notification::Priority::MODERATE
                           when 5 then Prowly::Notification::Priority::VERY_LOW
                           else Prowly::Notification::Priority::NORMAL
                        end
        prowl_priority
      end
    end
  end
end