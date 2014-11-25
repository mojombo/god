# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Send a notice to a SENSU client socket, port 3030 on 'localhost' only.
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# [mandatory]
# check_name    - a unique check name
#
# [optional]
# status_code   - status codes used are 0 for OK, 1 for WARNING, 2 for CRITICAL, and 3 or greater to indicate UNKNOWN or CUSTOM.
# handler       - default handler
#

CONTACT_DEPS[:sensu] = ['json']
CONTACT_DEPS[:sensu].each do |d|
  require d
end

module God
  module Contacts

    class Sensu < Contact
      class << self
        attr_accessor :check_name, :status_code, :handler
      end

      self.status_code = 2
      self.handler = 'default'

      def valid?
        valid = true
        valid &= complain("Attribute 'check_name' must be specified", self) unless arg(:check_name)
        valid
      end

      attr_accessor :check_name, :status_code, :handler

      def sensu_client_socket(msg)
        u = UDPSocket.new
        u.send(msg + "\n", 0, '127.0.0.1', 3030)
      end

      def notify(message, time, priority, category, host)
        data = {
          :category => category,
          :message => message,
          :priority => priority,
          :host => host,
          :time => time,
        }
        parcel = { 'name' => eval("\"" + arg(:check_name) + "\""), 'status' => arg(:status_code).nil? ? self.status_code : arg(:status_code), 'output' => data.to_json, 'handler' => arg(:handler).empty? ? self.handler : arg(:handler) }
        sensu_client_socket parcel.to_json
      end
    end
  end
end

