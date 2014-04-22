# Send a message to a Slack channel
#
# account        - The name of your Slack account (visible in URL, e.g. foo.slack.com)
# token          - The token of the webhook created in Slack
# channel        - The name of the channel to send the message to, prefixed with #
# notify_channel - Whether to send an "@channel" in the message, to alert everyone in the channel
# format         - An optional format string to change how the alert is displayed

require 'net/http'
require 'uri'

CONTACT_DEPS[:slack] = ['json']
CONTACT_DEPS[:slack].each do |d|
  require d
end

module God
  module Contacts

    class Slack < Contact
      class << self
        attr_accessor :account, :token, :channel, :notify_channel, :format
      end

      self.channel        = "#general"
      self.notify_channel = false
      self.format         = "%{priority} alert on %{host}: %{message} (%{category}, %{time})"

      def valid?
        valid = true
        valid &= complain("Attribute 'account' must be specified", self) unless arg(:account)
        valid &= complain("Attribute 'token' must be specified", self) unless arg(:token)
        valid
      end

      attr_accessor :account, :token, :channel, :notify_channel, :format

      def text(data)
        text = ""
        text << "<!channel> " if arg(:notify_channel)
        text << arg(:format) % data
      end

      def notify(message, time, priority, category, host)
        text = text({
          :message => message,
          :time => time,
          :priority => priority,
          :category => category,
          :host => host
        })

        request(text)
      end

      def api_url
        URI.parse("https://#{arg(:account)}.slack.com/services/hooks/incoming-webhook?token=#{arg(:token)}&channel=#{arg(:channel)}")
      end

      def request(text)
        http = Net::HTTP.new(api_url.host, api_url.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(api_url.request_uri)
        req.body = { text: text }.to_json

        res = http.request(req)

        case res
          when Net::HTTPSuccess
            self.info = "successfully notified slack on channel #{arg(:channel)}"
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

