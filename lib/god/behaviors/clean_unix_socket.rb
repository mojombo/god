module God
  module Behaviors

    class CleanUnixSocket < Behavior
      def valid?
        valid = true
        valid &= complain("Attribute 'unix_socket' must be specified", self) if self.watch.unix_socket.nil?
        valid
      end

      def before_start
        File.delete(self.watch.unix_socket)

        "deleted unix socket"
      rescue
        "no unix socket to delete"
      end
    end

  end
end
