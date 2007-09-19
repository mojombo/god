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
      start
    end

    def ping
      true
    end
    
    def method_missing(*args, &block)
      God.send(*args, &block)
    end

    private

    def start
      acl = ACL.new(@acl)
      DRb.install_acl(acl)
      
      begin
        @drb ||= DRb.start_service("druby://#{@host}:#{@port}", self)
        puts "Started on #{DRb.uri}"
      rescue Errno::EADDRINUSE
        DRb.start_service
        server = DRbObject.new nil, "druby://127.0.0.1:#{@port}"
        
        begin
          server.ping
          abort "Address #{@host}:#{@port} already in use by another instance of god"
        rescue
          abort "Address #{@host}:#{@port} already in use by a non-god process"
        end
      end
    end
  end

end
