require 'rubygems'
require 'daemons'

Daemons.run_proc('daemon-polls', {:dir_mode => :system}) do
  loop { puts 'server'; sleep 1 }
end