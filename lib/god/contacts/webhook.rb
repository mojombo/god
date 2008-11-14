# Configure your watches like this:
#
#   God.contact(:webhook) do |c|
#     c.name      = 'Tester'
#     c.hook_url  = 'http://hook/url'
#   end

require 'net/http'
require 'uri'

module God
  module Contacts

    class Webhook < Contact

      attr_accessor :hook_url

      def valid?
        valid = true
      end

      def notify(message, time, priority, category, host)
        begin
          data = {
            :message => message,
            :time => time,
            :priority => priority,
            :category => category,
            :host => host
          }

          uri = URI.parse(self.hook_url)
          Net::HTTP.post_form(uri, data)

          self.info = "sent webhook to #{self.hook_url}"
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")

          self.info = "failed to send webhook to #{self.hook_url}: #{e.message}"
        end
      end

    end

  end
end
