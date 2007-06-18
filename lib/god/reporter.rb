require File.dirname(__FILE__) + '/../god'
require 'drb'

module God

  class Reporter
    def initialize(host = nil, port = nil)
      @host = host
      @port = port || 7777
    end

    def method_missing(*args, &block)
      service.send(*args, &block)
    end

    private

    def service
      return @service if @service
      DRb.start_service
      @service = DRbObject.new(nil, "druby://#{@host}:#{@port}")
    end
  end

end
