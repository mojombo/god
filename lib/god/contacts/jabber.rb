# Send a notice to a Jabber address.
#
# host     - The String hostname of the Jabber server.
# port     - The Integer port of the Jabber server (default: 5222).
# from_jid - The String Jabber ID of the sender.
# password - The String password of the sender.
# to_jid   - The String Jabber ID of the recipient.
# subject  - The String subject of the message (default: "God Notification").

CONTACT_DEPS[:jabber] = ['xmpp4r']
CONTACT_DEPS[:jabber].each do |d|
  require d
end

module God
  module Contacts

    class Jabber < Contact
      class << self
        attr_accessor :host, :port, :from_jid, :password, :to_jid, :subject
        attr_accessor :format
      end

      self.port = 5222
      self.subject = 'God Notification'

      self.format = lambda do |message, time, priority, category, host|
        text  = "Message: #{message}\n"
        text += "Host: #{host}\n"         if host
        text += "Priority: #{priority}\n" if priority
        text += "Category: #{category}\n" if category
        text
      end

      attr_accessor :host, :port, :from_jid, :password, :to_jid, :subject

      def valid?
        valid = true
        valid &= complain("Attribute 'host' must be specified", self) unless arg(:host)
        valid &= complain("Attribute 'port' must be specified", self) unless arg(:port)
        valid &= complain("Attribute 'from_jid' must be specified", self) unless arg(:from_jid)
        valid &= complain("Attribute 'to_jid' must be specified", self) unless arg(:to_jid)
        valid &= complain("Attribute 'password' must be specified", self) unless arg(:password)
        valid
      end

      def notify(message, time, priority, category, host)
        body = Jabber.format.call(message, time, priority, category, host)

        message = ::Jabber::Message.new(arg(:to_jid), body)
        message.set_type(:normal)
        message.set_id('1')
        message.set_subject(arg(:subject))

        jabber_id = ::Jabber::JID.new("#{arg(:from_jid)}/God")

        client = ::Jabber::Client.new(jabber_id)
        client.connect(arg(:host), arg(:port))
        client.auth(arg(:password))
        client.send(message)
        client.close

        self.info = "sent jabber message to #{self.to_jid}"
      rescue Object => e
        if e.respond_to?(:message)
          applog(nil, :info, "failed to send jabber message to #{arg(:to_jid)}: #{e.message}")
        else
          applog(nil, :info, "failed to send jabber message to #{arg(:to_jid)}: #{e.class}")
        end
        applog(nil, :debug, e.backtrace.join("\n"))
      end

    end
  end
end
