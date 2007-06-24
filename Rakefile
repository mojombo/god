# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/god.rb'

Hoe.new('god', God::VERSION) do |p|
  p.rubyforge_name = 'god'
  # p.author = 'FIX'
  # p.email = 'FIX'
  # p.summary = 'FIX'
  # p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  # p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/god.rb"
end

desc "Upload site to Rubyforge"
task :site do
  sh "scp -r site/* mojombo@god.rubyforge.org:/var/www/gforge-projects/god"
end

# vim: syntax=Ruby
