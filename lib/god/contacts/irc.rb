# Send a notice to an IRC channel.
#
# host        - The String hostname of the IRC server.
# port        - The Integer port of the IRC server.
# channel     - The String IRC Channel.
# nick        - The String Nickname of the sender.
# realname    - The String Realname of the sender.

module God
  module Contacts
    class Irc < Contact
      class << self
        attr_accessor :host, :port, :channel, :nick, :realname
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'host' must be specified", self) unless arg(:host)
        valid &= complain("Attribute 'port' must be specified", self) unless arg(:port)
        valid &= complain("Attribute 'channel' must be specified", self) unless arg(:channel)
        valid &= complain("Attribute 'nick' must be specified", self) unless arg(:nick)
        valid &= complain("Attribute 'realname' must be specified", self) unless arg(:realname)
        valid
      end

      attr_accessor :host, :port, :channel, :nick, :realname

      def notify(message, time, priority, category, host)

        s = TCPSocket.open(arg(:host), arg(:port))
        s.puts("NICK #{arg(:nick)}")
        s.puts("USER #{arg(:nick)} 8 * : #{arg(:realname)}")
        s.puts "PRIVMSG #{arg(:channel)} :'" + message + "'"
        s.close

        self.info = "sent IRC update"

      rescue => e
        applog(nil, :info, "failed to send IRC update: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end
  end
end
