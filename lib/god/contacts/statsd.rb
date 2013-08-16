# Send a notice to statsd
#
# host - statsd host
# port - statsd port (optional)

require 'statsd-ruby'

module God
  module Contacts

    class Statsd < Contact
      class << self
        attr_accessor :host, :port
      end

      attr_accessor :host, :port

      def valid?
        valid = true
        valid &= complain("Attribute 'statsd_host' must be specified", self) unless arg(:host)
        valid
      end

      def notify(message, time, priority, category, hostname)
        statsd = ::Statsd.new host, (port ? port.to_i : 8125) # 8125 is the default statsd port

        hostname.gsub! /\./, '_'
        app = message.gsub /([^\s]*).*/, '\1'

        [
            'cpu out of bounds',
            'memory out of bounds',
            'process is flapping'
        ].each do |event_type|
          statsd.increment "god.#{event_type.gsub(/\s/, '_')}.#{hostname}.#{app}" if message.include? event_type
        end

        self.info = 'sent statsd alert'
      rescue => e
        applog(nil, :info, "failed to send statsd alert: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end

  end
end
