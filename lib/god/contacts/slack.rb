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
        attr_accessor :url, :channel, :notify_channel, :format, :username, :emoji
      end

      self.channel        = "#general"
      self.notify_channel = false
      self.format         = "%{priority} alert on %{host}: %{message} (%{category}, %{time})"

      def valid?
        valid = true
        valid &= complain("Attribute 'url' must be specified", self) unless arg(:url)
        valid
      end

      attr_accessor :url, :channel, :notify_channel, :format, :username, :emoji

      def text(data)
        text = ""
        text << "<!channel> " if arg(:notify_channel)

        if RUBY_VERSION =~ /^1\.8/
          text << arg(:format).gsub(/%\{(\w+)\}/) do |match|
            data[$1.to_sym]
          end
        else
          text << arg(:format) % data
        end

        text
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
        URI.parse arg(:url)
      end

      def request(text)
        http = Net::HTTP.new(api_url.host, api_url.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(api_url.request_uri)
        req.body = {
          :link_names => 1,
          :text => text,
          :channel => arg(:channel)
        }.tap { |payload|
          payload[:username] = arg(:username) if arg(:username)
          payload[:icon_emoji] = arg(:emoji) if arg(:emoji)
        }.to_json

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