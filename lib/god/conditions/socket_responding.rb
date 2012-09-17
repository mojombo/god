require 'socket'
include Socket::Constants

module God
  module Conditions
    # Condition Symbol :socket_running
    # Type: Poll
    #
    # Trigger when a TCP or UNIX socket is running or not
    #
    # Parameters
    # Required
    #   +family+ is the family of socket: either 'tcp' or 'unix'
    #   --one of port or path--
    #   +port+ is the port (required if +family+ is 'tcp')
    #   +path+ is the path (required if +family+ is 'unix')
    #
    # Examples
    #
    # Trigger if the TCP socket on port 80 is not responding or the connection is refused
    #
    # on.condition(:socket_responding) do |c|
    #   c.family = 'tcp'
    #   c.port = '80'
    # end
    #
    # Trigger if the socket is not responding or the connection is refused (use alternate compact +socket+ interface)
    #
    # on.condition(:socket_responding) do |c|
    #   c.socket = 'tcp:80'
    # end
    #
    # Trigger if the socket is not responding or the connection is refused 5 times in a row
    #
    # on.condition(:socket_responding) do |c|
    #   c.socket = 'tcp:80'
    #   c.times = 5
    # end
    #
    # Trigger if the Unix socket on path '/tmp/sock' is not responding or non-existent
    #
    # on.condition(:socket_responding) do |c|
    #   c.family = 'unix'
    #   c.port = '/tmp/sock'
    # end
    #


    class SocketResponding < PollCondition
      attr_accessor :family, :addr, :port, :path, :times

      def initialize
        super
        # default to tcp on the localhost
        self.family = 'tcp'
        self.addr = '127.0.0.1'
        # Set these to nil/0 values
        self.port = 0
        self.path = nil

        self.times = [1, 1]
      end

      def prepare
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end

        @timeline = Timeline.new(self.times[1])
        @history = Timeline.new(self.times[1])
      end

      def reset
        @timeline.clear
        @history.clear
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
        valid = false unless %w{tcp unix}.member?(self.family)
        valid
      end

      def test
        self.info = []
        if self.family == 'tcp'
          begin
            s = TCPSocket.new(self.addr, self.port)
          rescue SystemCallError
          end
          status = s.nil?
        elsif self.family == 'unix'
          begin
            s = UNIXSocket.new(self.path)
          rescue SystemCallError
          end
          status = s.nil?
        else
          status = false
        end
        @timeline.push(status)
        history = "[" + @timeline.map {|t| t ? '*' : ''}.join(',') + "]"
        if @timeline.select { |x| x }.size >= self.times.first
          self.info = "socket out of bounds #{history}"
          return true
        else
          return false
        end
      end
    end
  end
end
