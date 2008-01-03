#! /usr/bin/env ruby

data = ''
    
loop do
  STDOUT.puts('server');
  STDOUT.flush;
  
  100000.times { data << 'x' }
  
  sleep 10
end