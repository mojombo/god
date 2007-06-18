require 'drb'

# The God::Server oversees the DRb server which dishes out info on this God daemon.

module God

  class Server
    attr_reader :host, :port

    def initialize(meddle = nil, host = nil, port = nil)
      @meddle = meddle
      @host = host
      @port = port || 7777
      start
    end

    def method_missing(*args, &block)
      @meddle.send(*args, &block)
    end

    private

    def start
      @drb ||= DRb.start_service("druby://#{@host}:#{@port}", self) 
    end
  end

end
