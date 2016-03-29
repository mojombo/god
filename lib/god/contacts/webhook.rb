# Send a notice to a webhook.
#
# url          - The String webhook URL.
# format       - The Symbol format [ :form | :json ] (default: :form).
# process_data - The optional Proc that returns a custom data object to send to the webhook.

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
        attr_accessor :url, :format, :process_data
      end

      self.format = :form
      self.process_data = nil

      def valid?
        valid = true
        valid &= complain("Attribute 'url' must be specified", self) unless arg(:url)
        valid &= complain("Attribute 'format' must be one of [ :form | :json ]", self) unless [:form, :json].include?(arg(:format))
        valid &= complain("Attribute 'process_data' must be a proc object if defined ", self) unless arg(:process_data).nil? || arg(:process_data).is_a?(Proc)
        valid
      end

      attr_accessor :url, :format, :process_data

      def notify(message, time, priority, category, host)
        if arg(:process_data)
          data = arg(:process_data).call(message, time, priority, category, host)
        else
          data = {
            :message => message,
            :time => time,
            :priority => priority,
            :category => category,
            :host => host
          }
        end

        uri = URI.parse(arg(:url))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == "https"

        req = nil
        res = nil

        case arg(:format)
          when :form
            req = Net::HTTP::Post.new(uri.request_uri)
            req.set_form_data(data)
          when :json
            req = Net::HTTP::Post.new(uri.request_uri)
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
        applog(nil, :info, "failed to send webhook to #{arg(:url)}: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end

    end

  end
end
