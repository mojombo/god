require 'net/http'

module God
  module Conditions
    
    class HttpResponseCode < PollCondition
      attr_accessor :code_is,      # e.g. 500 or '500' or [404, 500] or %w{404 500}
                    :code_is_not,  # e.g. 200 or '200' or [200, 302] or %w{200 302}
                    :times,        # e.g. 3 or [3, 5]
                    :host,         # e.g. www.example.com
                    :port,         # e.g. 8080
                    :timeout,      # e.g. 60.seconds
                    :path          # e.g. '/'
      
      def initialize
        super
        self.times = [1, 1]
      end
      
      def prepare
        self.code_is = Array(self.code_is).map { |x| x.to_i } if self.code_is
        self.code_is_not = Array(self.code_is_not).map { |x| x.to_i } if self.code_is_not
        
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
        
        actual_response_code = response.code.to_i
        if self.code_is && self.code_is.include?(actual_response_code)
          pass(actual_response_code)
        elsif self.code_is_not && !self.code_is_not.include?(actual_response_code)
          pass(actual_response_code)
        else
          fail(actual_response_code)
        end
      rescue Timeout::Error
        self.code_is ? fail('Timeout') : pass('Timeout')
      end
      
      private
      
      def pass(code)
        @timeline << true
        if @timeline.select { |x| x }.size >= self.times.first
          self.info = "http response abnormal #{history(code, true)}"
          true
        else
          self.info = "http response nominal #{history(code, true)}"
          false
        end
      end
      
      def fail(code)
        @timeline << false
        self.info = "http response nominal #{history(code, false)}"
        false
      end
      
      def history(code, passed)
        entry = code.to_s.dup
        entry = '*' + entry if passed
        @history << entry
        '[' + @history.join(", ") + ']'
      end
      
    end
    
  end
end