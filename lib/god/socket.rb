require 'drb'

module God

  # The God::Server oversees the DRb server which dishes out info on this God daemon.
  class Socket
    attr_reader :port

    # The location of the socket for a given port
    #   +port+ is the port number
    #
    # Returns String (file location)
    def self.socket_file(port)
      "/tmp/god.#{port}.sock"
    end

    # The address of the socket for a given port
    #   +port+ is the port number
    #
    # Returns String (drb address)
    def self.socket(port)
      "drbunix://#{self.socket_file(port)}"
    end

    # The location of the socket for this Server
    #
    # Returns String (file location)
    def socket_file
      self.class.socket_file(@port)
    end

    # The address of the socket for this Server
    #
    # Returns String (drb address)
    def socket
      self.class.socket(@port)
    end

    # Create a new Server and star the DRb server
    #   +port+ is the port on which to start the DRb service (default nil)
    def initialize(port = nil, user = nil, group = nil, perm = nil)
      @port  = port
      @user  = user
      @group = group
      @perm  = perm
      start
    end

    # Returns true
    def ping
      true
    end

    # Forward API calls to God
    #
    # Returns whatever the forwarded call returns
    def method_missing(*args, &block)
      God.send(*args, &block)
    end

    # Stop the DRb server and delete the socket file
    #
    # Returns nothing
    def stop
      DRb.stop_service
      FileUtils.rm_f(self.socket_file)
    end

    private

    # Start the DRb server. Abort if there is already a running god instance
    # on the socket.
    #
    # Returns nothing
    def start
      begin
        @drb ||= DRb.start_service(self.socket, self)
        applog(nil, :info, "Started on #{DRb.uri}")
      rescue Errno::EADDRINUSE
        applog(nil, :info, "Socket already in use")
        DRb.start_service
        server = DRbObject.new(nil, self.socket)

        begin
          Timeout.timeout(5) do
            server.ping
          end
          abort "Socket #{self.socket} already in use by another instance of god"
        rescue StandardError, Timeout::Error
          applog(nil, :info, "Socket is stale, reopening")
          File.delete(self.socket_file) rescue nil
          @drb ||= DRb.start_service(self.socket, self)
          applog(nil, :info, "Started on #{DRb.uri}")
        end
      end

      if File.exists?(self.socket_file)
        uid = Etc.getpwnam(@user).uid if @user
        gid = Etc.getgrnam(@group).gid if @group

        File.chmod(Integer(@perm), socket_file) if @perm
        File.chown(uid, gid, socket_file) if uid or gid
      end
    end
  end

end
