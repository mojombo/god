# Send a notice to a Hipchat room (http://hipchat.com).
#
#  token     - The String token used for authentication.
#  room      - The String room name to which the message should be sent.
#  ssl       - A Boolean determining whether or not to use SSL
#              (default: false).
#  from      - The String representing who the message should be sent as.

require 'net/http'
require 'net/https'

CONTACT_DEPS[:hipchat] = ['json']
CONTACT_DEPS[:hipchat].each do |d|
  require d
end

module Marshmallow
  class Connection
    def initialize(options)
      raise "Required option :token not set." unless options[:token]
      @options = options
    end

    def base_url
      scheme = @options[:ssl] ? 'https' : 'http'
      "#{scheme}://api.hipchat.com/v1/rooms"
    end

    def find_room_id_by_name(room_name)
      url = URI.parse("#{base_url}/list?format=json&auth_token=#{@options[:token]}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if @options[:ssl]

      req = Net::HTTP::Get.new(url.request_uri)
      req.set_content_type('application/json')

      res = http.request(req)
      case res
        when Net::HTTPSuccess
          rooms = JSON.parse(res.body)
          room = rooms['rooms'].select { |x| x['name'] == room_name }
          rooms.empty? ? nil : room.first['room_id'].to_i
        else
          raise res.error!
      end
    end

    def speak(room, message)
      room_id = find_room_id_by_name(room)
      puts "in spark: room_id = #{room_id}"
      raise "No such room: #{room}." unless room_id

      escaped_message = URI.escape(message)

      url = URI.parse("#{base_url}/message?message_format=text&format=json&auth_token=#{@options[:token]}&from=#{@options[:from]}&room_id=#{room}&message=#{escaped_message}")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if @options[:ssl]

      req = Net::HTTP::Post.new(url.request_uri)
      req.set_content_type('application/json')
      res = http.request(req)
      case res
        when Net::HTTPSuccess
          true
        else
          raise res.error!
      end
    end
  end
end

module God
  module Contacts

    class Hipchat < Contact
      class << self
        attr_accessor :token, :room, :ssl, :from
        attr_accessor :format
      end

      self.ssl = false

      self.format = lambda do |message, time, priority, category, host|
        "[#{time.strftime('%H:%M:%S')}] #{host} - #{message}"
      end

      attr_accessor :token, :room, :ssl, :from

      def valid?
        valid = true
        valid &= complain("Attribute 'token' must be specified", self) unless arg(:token)
        valid &= complain("Attribute 'room' must be specified", self) unless arg(:room)
        valid &= complain("Attribute 'from' must be specified", self) unless arg(:from)
        valid
      end

      def notify(message, time, priority, category, host)
        body = Hipchat.format.call(message, time, priority, category, host)

        conn = Marshmallow::Connection.new(
          :token => arg(:token),
          :ssl   => arg(:ssl),
          :from  => arg(:from)
        )

        conn.speak(arg(:room), body)

        self.info = "notified hipchat: #{arg(:room)}"
      rescue Object => e
        applog(nil, :info, "failed to notify hipchat: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end

  end
end
