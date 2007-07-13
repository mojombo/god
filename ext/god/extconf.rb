require 'mkmf'

case RUBY_PLATFORM
when /bsd/i, /darwin/i
  create_makefile 'kqueue_handler_ext'
when /linux/i
  create_makefile 'netlink_handler_ext'
end
