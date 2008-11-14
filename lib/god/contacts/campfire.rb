# notify campfire using tinder http://tinder.rubyforge.org
#
#  Example: set up a new campfire notifier
#
#  Credentials
#
#  God::Contacts::Campfire.server_settings = {
#     :subdomain => "yoursubdomain",
#     :user_name => "youruser",
#     :room => "yourroom",
#     :password => "yourpassword"
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

require 'tinder'

module God
  module Contacts
    
    class Campfire < Contact
      class << self
        attr_accessor :server_settings, :format
        def room
          unless @room
            applog(nil,:debug, "initializing campfire connection using credentials: #{Campfire.server_settings.inspect}")
            
            campfire = Tinder::Campfire.new Campfire.server_settings[:subdomain] 
            campfire.login Campfire.server_settings[:user_name], Campfire.server_settings[:password]
            @room = campfire.find_room_by_name(Campfire.server_settings[:room])
          end
          @room
        end
      end
      
      self.server_settings = {:subdomain => '',
                              :user_name => '',
                              :password => '',
                              :room => ''}

      self.format = lambda do |message, host|
        <<-EOF
        #{host} - #{message}
        EOF
      end
      
      def valid?
        true
      end
      
      def notify(message, time, priority, category, host)
        
        begin
          body = Campfire.format.call(message,host)
          
          Campfire.room.speak body

          self.info = "notified campfire: #{Campfire.server_settings[:subdomain]}"
        rescue => e
          applog(nil, :info, "failed to notify campfire: #{e.message}")
          applog(nil, :debug, e.backtrace.join("\n"))
        end
      end
    end

  end
end