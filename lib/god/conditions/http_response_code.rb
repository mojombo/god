require 'net/http'

module God
  module Conditions
    
    class HttpResponseCode < PollCondition
      attr_accessor :code_is, :code_is_not, :times, :host, :port, :timeout, :path
    
      def initialize
        super
        self.times = [1, 1]
      end
      
      def prepare
        self.code_is = Array(self.code) if self.code_is
        self.code_is_not = Array(self.code_is_not) if self.code_is_not
        
        if self.times.kind_of?(Integer)
          self.times = [self.times, self.times]
        end
        
        @timeline = Timeline.new(self.times[1])
      end
    
      def valid?
        valid = true
        valid &= complain("Attribute 'host' must be specified", self) if self.host.nil?
        valid &= complain("Attribute 'port' must be specified", self) if self.port.nil?
        valid &= complain("Attribute 'path' must be specified", self) if self.path.nil?
        valid &= complain("One (and only one) of attributes 'code_is' and 'code_is_not' must be specified", self) if
          (self.code_is.nil? && self.code_is_not.nil?) || (self.code_is && self.code_is_not)
        valid &= complain("Attribute 'timeout' must be specified", self) if self.timeout.nil?
        valid
      end
    
      def test
        response = nil
        
        Net::HTTP.start(self.host, self.port) do |http|
          http.read_timeout = self.timeout
          response = http.head(self.path)
        end
        
        if self.code_is && self.code_is.include?(response.code)
          pass
        elsif self.code_is_not && !self.code.include?(response.code)
          pass
        else
          false
        end
      rescue Timeout::Error
        self.code_is ? false : pass
      end
      
      private
      
      def pass
        @timeline.clear
        return true
      end
      
    end
    
  end
end