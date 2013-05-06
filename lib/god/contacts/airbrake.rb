# Send a notice to Airbrake (http://airbrake.io/).
#
# apikey - The String API key.

CONTACT_DEPS[:airbrake] = ['airbrake']
CONTACT_DEPS[:airbrake].each do |d|
  require d
end

module God
  module Contacts
    class Airbrake < Contact

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
        ::Airbrake.configure {}

        message = "God: #{message.to_s} at #{host}"
        message << " | #{[category, priority].join(" ")}" unless category.to_s.empty? or priority.to_s.empty?

        if ::Airbrake.notify nil, :error_message => message, :api_key => arg(:apikey)
          self.info = "sent airbrake notification to #{self.name}"
        else
          self.info = "failed to send airbrake notification to #{self.name}"
        end
      rescue Object => e
        applog(nil, :info, "failed to send airbrake notification: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end

    end
  end
end
