# Send HTTP/POST request.
#
# url - The String URL

require 'net/http'
require 'net/https'

module God
  module Contacts
    class HttpPost < Contact
      class << self
        attr_accessor :url
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'url' must be specified", self) unless arg(:url)
        valid
      end

      attr_accessor :url

      def notify(message, time, priority, category, host)
        uri = URI.parse(arg(:url))
        http = Net::HTTP.new uri.host, uri.port
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        post = Net::HTTP::Post.new uri.request_uri
        post.set_form_data({ message: message,
                             time: time,
                             priority: priority,
                             category: category,
                             host: host })
        response = http.request(post)

        self.info = "sent http/post request"
      rescue => e
        applog(nil, :info, "failed to send http/post request: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end
  end
end
