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
      
      attr_accessor :apikey, :priority, :application, :event, :description
      
      def valid?
        valid = true
      end

      def notify(message, time, priority, category, host)
        begin
          result = Prowly.notify do |n|
            n.apikey      = self.apikey
            n.priority    = Prowly::Notification::Priority::HIGH
            n.application = ""
            n.event       = "Event at " + time
            n.description = message
          end

          if result.succeeded?
            self.info = "sent prowl notification to #{self.name}"
          else
            self.info = "failed to send prowl notification to #{self.name}: #{result.message}"
          end
        end
      end
    end
  end
end