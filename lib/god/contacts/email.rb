# Send a notice to an email address.
#
# to_email        - The String email address to which the email will be sent.
# to_name         - The String name corresponding to the recipient.
# from_email      - The String email address from which the email will be sent.
# from_name       - The String name corresponding to the sender.
# delivery_method - The Symbol delivery method. [ :smtp | :sendmail ]
#                   (default: :smtp).
#
# === SMTP Options (when delivery_method = :smtp) ===
# server_host     - The String hostname of the SMTP server (default: localhost).
# server_port     - The Integer port of the SMTP server (default: 25).
# server_auth     - The Symbol authentication method. Possible values:
#                   [ nil | :plain | :login | :cram_md5 ]
#                   The default is nil, which means no authentication. To
#                   enable authentication, pass the appropriate symbol and
#                   then pass the appropriate SMTP Auth Options (below).
#
# === SMTP Auth Options (when server_auth != nil) ===
# server_domain   - The String domain.
# server_user     - The String username.
# server_password - The String password.
#
# === Sendmail Options (when delivery_method = :sendmail) ===
# sendmail_path   - The String path to the sendmail executable
#                   (default: "/usr/sbin/sendmail").
# sendmail_args   - The String args to send to sendmail (default "-i -t").

require 'time'
require 'net/smtp'

module God
  module Contacts

    class Email < Contact
      class << self
        attr_accessor :to_email, :to_name, :from_email, :from_name,
                      :delivery_method, :server_host, :server_port,
                      :server_auth, :server_domain, :server_user,
                      :server_password, :sendmail_path, :sendmail_args
        attr_accessor :format
      end

      self.from_email = 'god@example.com'
      self.from_name = 'God Process Monitoring'
      self.delivery_method = :smtp
      self.server_auth = nil
      self.server_host = 'localhost'
      self.server_port = 25
      self.sendmail_path = '/usr/sbin/sendmail'
      self.sendmail_args = '-i -t'

      self.format = lambda do |name, from_email, from_name, to_email, to_name, message, time, priority, category, host|
        <<-EOF
From: #{from_name} <#{from_email}>
To: #{to_name || name} <#{to_email}>
Subject: [god] #{message}
Date: #{time.httpdate}
Message-Id: <#{rand(1000000000).to_s(36)}.#{$$}.#{from_email}>

Message: #{message}
Host: #{host}
Priority: #{priority}
Category: #{category}
        EOF
      end

      attr_accessor :to_email, :to_name, :from_email, :from_name,
                    :delivery_method, :server_host, :server_port,
                    :server_auth, :server_domain, :server_user,
                    :server_password, :sendmail_path, :sendmail_args

      def valid?
        valid = true
        valid &= complain("Attribute 'to_email' must be specified", self) unless arg(:to_email)
        valid &= complain("Attribute 'delivery_method' must be one of [ :smtp | :sendmail ]", self) unless [:smtp, :sendmail].include?(arg(:delivery_method))
        if arg(:delivery_method) == :smtp
          valid &= complain("Attribute 'server_host' must be specified", self) unless arg(:server_host)
          valid &= complain("Attribute 'server_port' must be specified", self) unless arg(:server_port)
          if arg(:server_auth)
            valid &= complain("Attribute 'server_domain' must be specified", self) unless arg(:server_domain)
            valid &= complain("Attribute 'server_user' must be specified", self) unless arg(:server_user)
            valid &= complain("Attribute 'server_password' must be specified", self) unless arg(:server_password)
          end
        end
        valid
      end

      def notify(message, time, priority, category, host)
        body = Email.format.call(self.name, arg(:from_email), arg(:from_name),
                                 arg(:to_email), arg(:to_name), message, time,
                                 priority, category, host)

        case arg(:delivery_method)
          when :smtp
            notify_smtp(body)
          when :sendmail
            notify_sendmail(body)
        end

        self.info = "sent email to #{arg(:to_email)} via #{arg(:delivery_method).to_s}"
      rescue Object => e
        applog(nil, :info, "failed to send email to #{arg(:to_email)} via #{arg(:delivery_method).to_s}: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end

      def notify_smtp(mail)
        args = [arg(:server_host), arg(:server_port)]
        if arg(:server_auth)
          args << arg(:server_domain)
          args << arg(:server_user)
          args << arg(:server_password)
          args << arg(:server_auth)
        end

        Net::SMTP.start(*args) do |smtp|
          smtp.send_message(mail, arg(:from_email), arg(:to_email))
        end
      end

      def notify_sendmail(mail)
        IO.popen("#{arg(:sendmail_path)} #{arg(:sendmail_args)}","w+") do |sm|
          sm.print(mail.gsub(/\r/, ''))
          sm.flush
        end
      end
    end

  end
end
