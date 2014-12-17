#! /usr/bin/env ruby

Signal.trap 'USR1' do
  puts "can't stop won't stop"
end

loop do
  puts 'server'
  sleep 1
end
