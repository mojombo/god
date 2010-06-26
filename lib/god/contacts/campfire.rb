# notify campfire using tinder http://tinder.rubyforge.org
#
#  Example: set up a new campfire notifier
#
#  Credentials
#
#  God::Contacts::Campfire.server_settings = {
#     :subdomain => "awesome",
#     :token => "421975cc0cb46e12fb4ff9983076c6ff39f4f68e",
#     :room => "Awesome Room",
#     :ssl => true
#  }
#
#  Register a new notifier
#
#  God.contact(:campfire) do |c|
#     c.name = 'campfire'
#  end
#
#  Define a transition for the process running event
#
#   w.transition(:up, :start) do |on|
#     on.condition(:process_running) do |c|
#        c.running = true
#        c.notify = 'campfire'
#     end
#   end

require 'net/http'
require 'net/https'
require 'json'

module Marshmallow
  class Connection
    def initialize(options)
      raise "Required option :subdomain not set." unless options[:subdomain]
      raise "Required option :token not set." unless options[:token]
      @options = options
    end

    def base_url
      scheme = @options[:ssl] ? 'https' : 'http'
      subdomain = @options[:subdomain]
      "#{scheme}://#{subdomain}.campfirenow.com"
    end

    def find_room_id_by_name(room)
      url = URI.parse("#{base_url}/rooms.json")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if @options[:ssl]

      req = Net::HTTP::Get.new(url.path)
      req.basic_auth(@options[:token], 'X')

      res = http.request(req)
      case res
        when Net::HTTPSuccess
          rooms = JSON.parse(res.body)
          room = rooms['rooms'].select { |x| x['name'] == room }
          rooms.empty? ? nil : room.first['id']
        else
          raise res.error!
      end
    end

    def speak(room, message)
      room_id = find_room_id_by_name(room)
      raise "No such room: #{room}." unless room_id

      url = URI.parse("#{base_url}/room/#{room_id}/speak.json")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if @options[:ssl]

      req = Net::HTTP::Post.new(url.path)
      req.basic_auth(@options[:token], 'X')
      req.set_content_type('application/json')
      req.body = { 'message' => { 'body' => message } }.to_json

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

    class Campfire < Contact
      class << self
        attr_accessor :server_settings, :format
      end

      self.server_settings = { :subdomain => '',
                               :token => '',
                               :room => '',
                               :ssl => false }

      self.format = lambda do |message, time, priority, category, host|
        "[#{time.strftime('%H:%M:%S')}] #{host} - #{message}"
      end

      def notify(message, time, priority, category, host)
        body = Campfire.format.call(message, time, priority, category, host)

        conn = Marshmallow::Connection.new(
          :subdomain => Campfire.server_settings[:subdomain],
          :token => Campfire.server_settings[:token],
          :ssl => Campfire.server_settings[:ssl]
        )

        conn.speak(Campfire.server_settings[:room], body)

        self.info = "notified campfire: #{Campfire.server_settings[:subdomain]}"
      rescue Object => e
        applog(nil, :info, "failed to notify campfire: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end

  end
end
