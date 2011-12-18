require 'netlink_handler_ext'

module God
  class NetlinkHandler
    EVENT_SYSTEM = "netlink"

    def self.register_process(pid, events)
      # netlink doesn't need to do this
      # it just reads from the eventhandler actions to see if the pid
      # matches the list we're looking for -- Kev
    end
  end
end
