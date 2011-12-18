#! /usr/bin/env ruby

trap :USR1 do

end

loop do
  STDOUT.puts('server');
  STDOUT.flush;

  sleep 10
end
