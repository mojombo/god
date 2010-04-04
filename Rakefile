require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "god"
    gem.rubyforge_project = "god"
    gem.summary = 'Like monit, only awesome'
    gem.description = "God is an easy to configure, easy to extend monitoring framework written in Ruby."
    gem.email = "tom@mojombo.com"
    gem.homepage = "http://god.rubyforge.org/"
    gem.authors = ["Tom Preston-Werner"]
    gem.require_paths = ["lib", "ext"]
    gem.files.include("ext")
    gem.extensions << 'ext/god/extconf.rb'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/god.rb"
end

desc "Upload site to Rubyforge"
task :site do
  sh "scp -r site/* mojombo@god.rubyforge.org:/var/www/gforge-projects/god"
end

desc "Upload site to Rubyforge"
task :site_edge do
  sh "scp -r site/* mojombo@god.rubyforge.org:/var/www/gforge-projects/god/edge"
end

desc "Run rcov"
task :coverage do
  `rm -fr coverage`
  `rcov test/test_*.rb`
  `open coverage/index.html`
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    require 'yaml'
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "god #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end