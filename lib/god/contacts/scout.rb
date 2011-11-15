# Send a notice to Scout (http://scoutapp.com/).
#
# client_key - The String client key.
# plugin_id  - The String plugin id.

require 'net/http'
require 'uri'

module God
  module Contacts

    class Scout < Contact
      class << self
        attr_accessor :client_key, :plugin_id
        attr_accessor :format
      end

      self.format = lambda do |message, priority, category, host|
        text  = "Message: #{message}\n"
        text += "Host: #{host}\n"         if host
        text += "Priority: #{priority}\n" if priority
        text += "Category: #{category}\n" if category
        return text
      end

      attr_accessor :client_key, :plugin_id

      def valid?
        valid = true
        valid &= complain("Attribute 'client_key' must be specified", self) unless arg(:client_key)
        valid &= complain("Attribute 'plugin_id' must be specified", self) unless arg(:plugin_id)
        valid
      end

      def notify(message, time, priority, category, host)
        data = {
          :client_key => arg(:client_key),
          :plugin_id => arg(:plugin_id),
          :format => 'xml',
          'alert[subject]' => message,
          'alert[body]' => Scout.format.call(message, priority, category, host)
        }

        uri = URI.parse('http://scoutapp.com/alerts/create')
        Net::HTTP.post_form(uri, data)

        self.info = "sent scout alert to plugin ##{plugin_id}"
      rescue => e
        applog(nil, :info, "failed to send scout alert to plugin ##{plugin_id}: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end

  end
end
