require 'rubygems'
require 'rake'
require 'date'

def source_version
  line = File.read('lib/god.rb')[/^\s*VERSION = .*/]
  line.match(/.*VERSION = '(.*)'/)[1]
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
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "god #{source_version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

if defined?(Gem)
  task :release => :build do
    unless `git branch` =~ /^\* master$/
      puts "You must be on the master branch to release!"
      exit!
    end
    sh "git commit --allow-empty -a -m 'up to #{source_version}'"
    sh "git tag v#{source_version}"
    sh "git push origin master --tags"
    sh "gem push pkg/god-#{source_version}.gem"
  end

  task :build => :gemspec do
    sh 'mkdir -p pkg'
    sh 'gem build god.gemspec'
    sh 'mv *.gem pkg'
  end

  task :gemspec do
    # read spec file and split out manifest section
    spec = File.read('god.gemspec')
    head, manifest, tail = spec.split("  # = MANIFEST =\n")
    # replace version and date
    head.sub!(/\.version = '.*'/, ".version = '#{source_version}'")
    head.sub!(/\.date = '.*'/, ".date = '#{Date.today.to_s}'")
    # determine file list from git ls-files
    files = `git ls-files`.
      split("\n").
      sort.
      reject { |file| file =~ /^\./ }.
      reject { |file| file =~ /^(ideas|init|site)/ }.
      map { |file| "    #{file}" }.
      join("\n")
    # piece file back together and write...
    manifest = "  s.files = %w[\n#{files}\n  ]\n"
    spec = [head, manifest, tail].join("  # = MANIFEST =\n")
    File.open('god.gemspec', 'w') { |io| io.write(spec) }
    puts "updated god.gemspec"
  end
end