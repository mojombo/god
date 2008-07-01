require 'time'
require 'net/smtp'

module God
  module Contacts
    
    class Email < Contact
      class << self
        attr_accessor :message_settings, :delivery_method, :server_settings, :sendmail_settings, :format
      end
      
      self.message_settings = {:from => 'god@example.com'}
      
      self.delivery_method = :smtp # or :sendmail
      
      self.server_settings = {:address => 'localhost',
                              :port => 25}
                            # :domain
                            # :user_name
                            # :password
                            # :authentication

      self.sendmail_settings = {:location  => '/usr/sbin/sendmail',
                                :arguments => '-i -t'
      }
      
      self.format = lambda do |name, email, message, time, priority, category, host|
        <<-EOF
From: god <#{self.message_settings[:from]}>
To: #{name} <#{email}>
Subject: [god] #{message}
Date: #{Time.now.httpdate}
Message-Id: <unique.message.id.string@example.com>

Message: #{message}
Host: #{host}
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
      
      def notify(message, time, priority, category, host)
        begin
          body = Email.format.call(self.name, self.email, message, time, priority, category, host)

          case Email.delivery_method
          when :smtp
            notify_smtp(body)
          when :sendmail
            notify_sendmail(body)
          else
            raise "unknown delivery method: #{Email.delivery_method}"
          end
          
          self.info = "sent email to #{self.email}"
        rescue => e
          applog(nil, :info, "failed to send email to #{self.email}: #{e.message}")
          applog(nil, :debug, e.backtrace.join("\n"))
        end
      end

      private

      def notify_smtp(mail)
        args = [Email.server_settings[:address], Email.server_settings[:port]]
        if Email.server_settings[:authentication]
          args << Email.server_settings[:domain]
          args << Email.server_settings[:user_name]
          args << Email.server_settings[:password]
          args << Email.server_settings[:authentication] 
        end

        Net::SMTP.start(*args) do |smtp|
          smtp.send_message mail, Email.message_settings[:from], self.email
        end
      end

      def notify_sendmail(mail)
        IO.popen("#{Email.sendmail_settings[:location]} #{Email.sendmail_settings[:arguments]}","w+") do |sm|
          sm.print(mail.gsub(/\r/, ''))
          sm.flush
        end
      end
    end

  end
end
