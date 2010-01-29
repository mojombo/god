# Configure your Scout client key:
#
#   God::Contacts::Scout.client_key = '1qpw29ie38ur37yt5
#
# A client key is configured per god process. Inside this God process,
# you can create multiple Scout 'contacts' - which are actually Scout
# plugins. This allows you to use Scout's UI to configure who gets
# notifications for each plugin, and to disable notifications when you
# go on vacation, etc.
#
#   God.contact(:scout) do |c|
#     c.name      = 'scout_delayed_job_plugin'
#     c.plugin_id = '12345
#   end
#
#   God.contact(:scout) do |c|
#     c.name      = 'scout_apache_plugin'
#     c.plugin_id = '54312
#   end

require 'net/http'
require 'uri'

module God
  module Contacts
    class Scout < Contact
      class << self
        attr_accessor :client_key, :format
      end
      attr_accessor :plugin_id

      self.format = lambda do |message, priority, category, host|
        text  = "Message: #{message}\n"
        text += "Host: #{host}\n"         if host
        text += "Priority: #{priority}\n" if priority
        text += "Category: #{category}\n" if category
        return text
      end

      def valid?
        valid = true
      end

      def notify(message, time, priority, category, host)
        begin
          data = {
            :client_key => Scout.client_key,
            :plugin_id => plugin_id,
            :format => 'xml',
            'alert[subject]' => message,
            'alert[body]' => Scout.format.call(message, priority, category, host)
          }

          uri = URI.parse('http://scoutapp.com/alerts/create')
          Net::HTTP.post_form(uri, data)

          self.info = "sent scout alert to plugin ##{plugin_id}"
        rescue => e
          self.info = "failed to send scout alert to plugin ##{plugin_id}: #{e.message}"
        end
      end
    end
  end
end
