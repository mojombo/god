# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.new('god', '0.1.0') do |p|
  p.rubyforge_name = 'god'
  p.author = 'Tom Preston-Werner'
  p.email = 'tom@rubyisawesome.com'
  p.url = 'http://god.rubyforge.org/'
  p.summary = 'Like monit, only awesome'
  p.description = "God is an easy to configure, easy to extend monitoring framework written in Ruby."
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['daemons', '>=1.0.7']
  p.spec_extras = {:extensions => ['ext/god/extconf.rb']}
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
