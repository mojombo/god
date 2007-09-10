require 'time'
require 'net/smtp'

module God
  module Contacts
    
    class Email < Contact
      class << self
        attr_accessor :message_settings, :delivery_method, :server_settings, :format
      end
      
      self.message_settings = {:from => 'god@example.com'}
      
      self.delivery_method = :smtp
      
      self.server_settings = {}
      
      self.format = lambda do |name, email, message, time, priority, category|
        <<-EOF
From: god <#{self.message_settings[:from]}>
To: #{name} <#{email}>
Subject: [god] #{message}
Date: #{Time.now.httpdate}
Message-Id: <unique.message.id.string@example.com>

Message: #{message}
Priority: #{priority}
Category: #{category}
        EOF
      end
      
      attr_accessor :email
      
      def valid?
        valid = true
        valid &= complain("Attribute 'email' must be specified", self) if self.email.nil?
        valid
      end
      
      def notify(message, time, priority, category)
        begin
          body = Email.format.call(self.name, self.email, message, time, priority, category)
          
          puts body
          puts
          # Net::SMTP.start('localhost', 25) do |smtp|
          #   smtp.send_message body, Email.message_settings[:from], self.email
          # end
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
        end
      end
    end
    
  end
end