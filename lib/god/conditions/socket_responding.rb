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
        # Set these to nil/0 values
        self.port = 0
        self.path = nil
      end 

      def socket=(s)
        components = s.split(':')
        if components.size == 3
          @family,@addr,@port = components
          @port = @port.to_i
        elsif components[0] =~ /^tcp$/
          @family = components[0]
          @port = components[1].to_i
        elsif components[0] =~ /^unix$/
          @family = components[0]
          @path = components[1]
        end
      end

      def valid?
        valid = true
        if self.family == 'tcp' and @port == 0
          valid &= complain("Attribute 'port' must be specified for tcp sockets", self)
        end
        if self.family == 'unix' and self.path.nil?
          valid &= complain("Attribute 'path' must be specified for unix sockets", self)
        end
        valid
      end
      
      def test
        if self.family == 'tcp'
         begin
          s = TCPSocket.new(self.addr, self.port)
         rescue SystemCallError
         end 
         s.nil? ? false : true
       elsif self.family == 'unix'
         begin
          s = UNIXSocket.new(self.path)
         rescue SystemCallError
         end 
         s.nil? ? false : true
       else
         false
       end
      end
    end
  end
end
