require 'rubygems'
require 'daemons'

puts 'simple server ahoy!'

Daemons.run_proc('daemon-events', {:dir_mode => :system}) do
  loop { puts 'server'; sleep 1 }
end