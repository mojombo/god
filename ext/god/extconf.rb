require 'mkmf'

fail = false

def create_dummy_makefile
  File.open("Makefile", 'w') do |f|
    f.puts "all:"
    f.puts "install:"
  end
end

case RUBY_PLATFORM
when /bsd/i, /darwin/i
  unless have_header('sys/event.h')
    puts
    puts "Missing 'sys/event.h' header"
    fail = true
  end

  if fail
    puts
    puts "Events handler could not be compiled (see above error). Your god installation will not support event conditions."
    create_dummy_makefile
  else
    create_makefile 'kqueue_handler_ext'
  end
when /linux/i
  unless have_header('linux/netlink.h')
    puts
    puts "Missing 'linux/netlink.h' header(s)"
    puts "You may need to install a header package for your system"
    fail = true
  end

  unless have_header('linux/connector.h') && have_header('linux/cn_proc.h')
    puts
    puts "Missing 'linux/connector.h', or 'linux/cn_proc.h' header(s)"
    puts "These are only available in Linux kernel 2.6.15 and later (run `uname -a` to find yours)"
    puts "You may need to install a header package for your system"
    fail = true
  end

  if fail
    puts
    puts "Events handler could not be compiled (see above error). Your god installation will not support event conditions."
    create_dummy_makefile
  else
    create_makefile 'netlink_handler_ext'
  end
else
  puts
  puts "Unsupported platform '#{RUBY_PLATFORM}'. Supported platforms are BSD, DARWIN, and LINUX."
  puts "Your god installation will not support event conditions."
  create_dummy_makefile
end
