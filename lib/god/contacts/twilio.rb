# Send a TXT message via Twilio (http://twilio.com/).
#
# account_sid - Your account SID
# auth_token  - Your account auth secret token

CONTACT_DEPS[:twilio] = ['twilio-ruby']
CONTACT_DEPS[:twilio].each do |d|
  require d
end

module God
  module Contacts
    class Twilio < Contact
      class << self
        attr_accessor :account_sid, :auth_token, :from_number, :to_number
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'account_sid' must be specified", self) unless arg(:account_sid)
        valid &= complain("Attribute 'auth_token' must be specified", self)  unless arg(:auth_token)
        valid &= complain("Attribute 'from_number' must be specified", self) unless arg(:from_number)
        valid &= complain("Attribute 'to_number' must be specified", self)   unless arg(:to_number)
        valid
      end

      attr_accessor :account_sid, :auth_token, :from_number, :to_number

      def notify(message, time, priority, category, host)
        client.account.sms.messages.create \
          :from => arg(:from_number),
          :to   => arg(:to_number),
          :body => message


        self.info = "sent txt message to #{self.to_number}"
      rescue => e
        applog(nil, :info, "failed to send txt message: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end

      private

      def client
        @client ||= ::Twilio::REST::Client.new arg(:account_sid), arg(:auth_token)
      end
    end
  end
end
