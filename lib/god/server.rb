require 'drb'
require 'drb/acl'

# The God::Server oversees the DRb server which dishes out info on this God daemon.

module God

  class Server
    attr_reader :host, :port

    def initialize(host = nil, port = nil, allow = [])
      @host = host
      @port = port
      @acl = %w{deny all} + allow.inject([]) { |acc, a| acc + ['allow', a] }
      puts "Starting on #{@host}:#{@port}"
      start
    end

    def method_missing(*args, &block)
      God.send(*args, &block)
    end

    private

    def start
      acl = ACL.new(@acl)
      DRb.install_acl(acl)
      
      @drb ||= DRb.start_service("druby://#{@host}:#{@port}", self) 
    end
  end

end
