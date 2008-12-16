# To add Jabber notifications you must have xmpp4r gem installed.
# Configure your watches like this:
#
#   God::Contacts::Jabber.settings = { :jabber_id => 'sender@example.com',
#                                      :password  => 'secret' }
#   God.contact(:jabber) do |c|
#     c.name      = 'Tester'
#     c.jabber_id = 'receiver@example.com'
#     c.group     = 'developers'
#   end

module XMPP4R
  require 'rubygems'
  require 'xmpp4r'
  include Jabber
end

module God
  module Contacts
    class Jabber < Contact      
      class << self
        attr_accessor :settings, :format
      end
      
      self.format = lambda do |message, priority, category, host|
        text  = "Message: #{message}\n"
        text += "Host: #{host}\n"         if host
        text += "Priority: #{priority}\n" if priority
        text += "Category: #{category}\n" if category
        return text
      end
      
      attr_accessor :jabber_id
      
      def valid?
        valid = true
      end
      
      def notify(message, time, priority, category, host)
        begin
          jabber_id = XMPP4R::JID::new "#{Jabber.settings[:jabber_id]}/God"
          jabber_client = XMPP4R::Client::new jabber_id
          jabber_client.connect Jabber.settings[:host]
          jabber_client.auth Jabber.settings[:password]

          body = Jabber.format.call message, priority, category, host
          
          message = XMPP4R::Message::new self.jabber_id, body
          message.set_type :normal
          message.set_id '1'
          message.set_subject 'God'
          jabber_client.send message

          self.info = "sent jabber message to #{self.jabber_id}"
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
          
          self.info = "failed to send jabber message to #{self.jabber_id}: #{e.message}"
        end
      end
    end
    
  end
end