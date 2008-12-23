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
        attr_accessor :settings, :format, :client
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
        connect
        
        body = Jabber.format.call message, priority, category, host
        
        message = XMPP4R::Message::new self.jabber_id, body
        message.set_type :normal
        message.set_id '1'
        message.set_subject 'God'
        
        self.send!(message)
        
        self.info = "sent jabber message to #{self.jabber_id}"
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
        
        self.info = "failed to send jabber message to #{self.jabber_id}: #{e.message}"
      end
      
      def send!(msg)
        attempts = 0
        begin
          attempts += 1
          client.send(msg)
        rescue Errno::EPIPE, IOError => e
          sleep 1
          disconnect!
          reconnect!
          retry unless attempts > 3
          raise e
        rescue Errno::ECONNRESET => e
          sleep (attempts^2) * 60 + 60
          disconnect!
          reconnect!
          retry unless attempts > 3
          raise e
        end
      end
      
      def connect
        connect! unless connected?
      end
      
      def connected?
        connected = client.respond_to?(:is_connected?) && client.is_connected?
        return connected
      end
      
      def connect!
        disconnect! if connected?

        @connect_mutex ||= Mutex.new
        # don't try to connect if another thread is already connecting.
        return if @connect_mutex.locked?
        @connect_mutex.lock
        
        jabber_id = XMPP4R::JID::new "#{Jabber.settings[:jabber_id]}/God"
        jabber_client = XMPP4R::Client::new jabber_id
        jabber_client.connect Jabber.settings[:host]
        jabber_client.auth Jabber.settings[:password]
        self.client = jabber_client
        
        @connect_mutex.unlock
      end
      
      def disconnect!
        if client.respond_to?(:is_connected?) && client.is_connected?
          begin
            client.close
          rescue Errno::EPIPE, IOError => e
            self.info "Failed to disconnect: #{e}"
            nil
          end
        end
        client = nil
      end

      def client
        Jabber.client
      end

      def client=(jc)
        Jabber.client = jc
      end

    end
  end
end