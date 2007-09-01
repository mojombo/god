require 'drb'

# The God::Server oversees the DRb server which dishes out info on this God daemon.

module God

  class Server
    attr_reader :host, :port

    def initialize(host = nil, port = nil)
      @host = host
      @port = port || 17165
      puts "Starting on #{@host}:#{@port}"
      start
    end

    def method_missing(*args, &block)
      God.send(*args, &block)
    end

    private

    def start
      @drb ||= DRb.start_service("druby://#{@host}:#{@port}", self) 
    end
  end

end
