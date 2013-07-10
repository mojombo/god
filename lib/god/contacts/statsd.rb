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
        statsd = ::Statsd.new statsd_host, (statsd_port.try(:to_i) || 8125) # 8125 is the default statsd port
        app = message.gsub  /\[god\] ([^-]*).*/, '\1'
        thin = message.gsub /.*thin-([^\s]*).*/, '\1'

        if message.include? 'cpu out of bounds'
          statsd.increment "god.#{app}.cpu_out_of_bounds.#{hostname}.#{thin}"
        elsif message.include? 'memory out of bounds'
          statsd.increment "god.#{app}.memory_out_of_bounds.#{hostname}.#{thin}"
        elsif message.include? 'process is flapping'
          statsd.increment "god.#{app}.flapping.#{hostname}.#{thin}"
        end

        self.info = 'sent statsd alert'
      rescue => e
        applog(nil, :info, "failed to send statsd alert: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end

  end
end
