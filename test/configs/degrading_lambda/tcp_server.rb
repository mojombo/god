#! /usr/bin/env ruby

require 'socket'
server = TCPServer.new('127.0.0.1', 9090)
while (session = server.accept)
  puts "Found a session"
  request = session.gets
  puts "Request: #{request}"
  time = request.to_i
  puts "Sleeping for #{time}"
  sleep time
  session.print "Slept for #{time} seconds"
  session.close
  puts "Session closed"
end
