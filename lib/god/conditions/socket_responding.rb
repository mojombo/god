require 'socket'
include Socket::Constants

module God
  module Conditions
    class SocketResponding < PollCondition
      attr_accessor :family, :addr, :port, :path
     
      def initialize
        super
        # default to tcp on the localhost
        self.family = 'tcp'
        self.addr = '127.0.0.1'
      end 

      def socket=(s)
        components = s.split(':')
        if components.size == 3
          @family,@addr,@port = components
        elsif components[0] =~ /^tcp$/
          @family = components[0]
          @port = components[1]
        elsif components[0] =~ /^unix$/
          @family = components[0]
          @path = components[1]
        end
      end

      def valid?
        valid = true
        if self.family == 'tcp' and self.port.nil?
          valid &= complain("Attribute 'port' must be specified for tcp sockets", self)
        end
        if self.family == 'unix' and self.path.nil?
          valid &= complain("Attribute 'path' must be specified for unix sockets", self)
        end
        valid
      end
      
      def test
        socket = Socket.new(AF_INET, SOCK_STREAM, 0)
        sockaddr = Socket.pack_sockaddr_in(self.port, self.addr)
        retval = socket.connect(sockaddr)
        close = socket.close()
        retval == 0 ? true : false
      end
    end
    
  end
end
