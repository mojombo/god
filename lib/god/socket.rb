require 'drb'

# The God::Server oversees the DRb server which dishes out info on this God daemon.

module God

  class Socket
    attr_reader :port
    
    def self.socket_file(port)
      "/tmp/god.#{port}.sock"
    end
    
    def self.socket(port)
      "drbunix://#{self.socket_file(port)}"
    end
    
    def socket_file
      self.class.socket_file(@port)
    end
    
    def socket
      self.class.socket(@port)
    end
    
    def initialize(port = nil)
      @port = port
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
      begin
        @drb ||= DRb.start_service(self.socket, self)
        applog(nil, :info, "Started on #{DRb.uri}")
      rescue Errno::EADDRINUSE
        DRb.start_service
        server = DRbObject.new(nil, self.socket)
        
        begin
          server.ping
          abort "Socket #{self.socket} already in use by another instance of god"
        rescue
          File.delete(self.socket_file) rescue nil
          @drb ||= DRb.start_service(self.socket, self)
        end
      end
    end
  end

end
