require 'drb'

# The God::Server oversees the DRb server which dishes out info on this God daemon.

module God

  class Server
    attr_reader :meddle, :host, :port

    def initialize(meddle = nil, host = nil, port = nil)
      @meddle = meddle
      @host = host
      @port = port || 17165
      start
    end

    def method_missing(*args, &block)
      @meddle.send(*args, &block)
    end
    
    def ping
      'pong'
    end

    private

    def start
      @drb ||= DRb.start_service("druby://#{@host}:#{@port}", self) 
    end
  end

end
