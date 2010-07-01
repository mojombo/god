# Send a notice to a webhook.
#
# url    - The String webhook URL.
# format - The Symbol format [ :form | :json ] (default: :form).

require 'net/http'
require 'uri'

CONTACT_DEPS[:webhook] = ['json']
CONTACT_DEPS[:webhook].each do |d|
  require d
end

module God
  module Contacts

    class Webhook < Contact
      class << self
        attr_accessor :url, :format
      end

      self.format = :form

      def valid?
        valid = true
        valid &= complain("Attribute 'url' must be specified", self) unless arg(:url)
        valid &= complain("Attribute 'format' must be one of [ :form | :json ]", self) unless [:form, :json].include?(arg(:format))
        valid
      end

      attr_accessor :url, :format

      def notify(message, time, priority, category, host)
        data = {
          :message => message,
          :time => time,
          :priority => priority,
          :category => category,
          :host => host
        }

        uri = URI.parse(arg(:url))
        http = Net::HTTP.new(uri.host, uri.port)

        req = nil
        res = nil

        case arg(:format)
          when :form
            req = Net::HTTP::Post.new(uri.path)
            req.set_form_data(data)
          when :json
            req = Net::HTTP::Post.new(uri.path)
            req.body = data.to_json
        end

        res = http.request(req)

        case res
          when Net::HTTPSuccess
            self.info = "sent webhook to #{arg(:url)}"
          else
            self.info = "failed to send webhook to #{arg(:url)}: #{res.error!}"
        end
      rescue Object => e
        applog(nil, :info, "failed to send email to #{arg(:url)}: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end

    end

  end
end
