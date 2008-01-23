# exit!(2)

3.times do
  puts 'waiting'
  sleep 1
end

p ENV

command = '/usr/local/bin/ruby ' + File.join(File.dirname(__FILE__), *%w[simple_server.rb]) + ' stop'
system(command)