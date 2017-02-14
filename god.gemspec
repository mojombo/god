Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'god'
  s.version = '0.13.7'
  s.date = '2015-10-19'

  s.summary = "Process monitoring framework."
  s.description = "An easy to configure, easy to extend monitoring framework written in Ruby."

  s.authors = ["Tom Preston-Werner", "Kevin Clark", "Eric Lindvall"]
  s.email = 'god-rb@googlegroups.com'
  s.homepage = 'http://god.rubyforge.org/'

  s.rubyforge_project = 'god'
  s.rubygems_version = '1.3.5'
  s.require_paths = %w[lib ext]

  s.executables = ["god"]
  s.extensions = %w[ext/god/extconf.rb]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md]

  s.add_development_dependency('json', '~> 1.6')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rdoc', '~> 3.10')
  s.add_development_dependency('twitter', '~> 5.0')
  s.add_development_dependency('prowly', '~> 0.3')
  s.add_development_dependency('xmpp4r', '~> 0.5')
  s.add_development_dependency('dike', '~> 0.0.3')
 # s.add_development_dependency('rcov', '~> 0.9')
  s.add_development_dependency('daemons', '~> 1.1')
  s.add_development_dependency('mocha', '~> 0.10')
  s.add_development_dependency('gollum', '~> 1.3.1')
  #the last version to support 1.8.7 is 0.99.6
  s.add_development_dependency('mustache', ['~> 0.99.0', '< 0.99.7'])
  s.add_development_dependency('airbrake', '~> 3.1.7')
  s.add_development_dependency('nokogiri', '~> 1.5.0')
  s.add_development_dependency('activesupport', [ '>= 2.3.10', '< 4.0.0' ])
  s.add_development_dependency('statsd-ruby')
  s.add_development_dependency('i18n', '< 0.7.0')
  # = MANIFEST =
  s.files = %w[
    Announce.txt
    Gemfile
    History.txt
    LICENSE
    README.md
    Rakefile
    bin/god
    doc/god.asciidoc
    doc/intro.asciidoc
    ext/god/.gitignore
    ext/god/extconf.rb
    ext/god/kqueue_handler.c
    ext/god/netlink_handler.c
    god.gemspec
    lib/god.rb
    lib/god/behavior.rb
    lib/god/behaviors/clean_pid_file.rb
    lib/god/behaviors/clean_unix_socket.rb
    lib/god/behaviors/notify_when_flapping.rb
    lib/god/cli/command.rb
    lib/god/cli/run.rb
    lib/god/cli/version.rb
    lib/god/compat19.rb
    lib/god/condition.rb
    lib/god/conditions/always.rb
    lib/god/conditions/complex.rb
    lib/god/conditions/cpu_usage.rb
    lib/god/conditions/degrading_lambda.rb
    lib/god/conditions/disk_usage.rb
    lib/god/conditions/file_mtime.rb
    lib/god/conditions/file_touched.rb
    lib/god/conditions/flapping.rb
    lib/god/conditions/http_response_code.rb
    lib/god/conditions/lambda.rb
    lib/god/conditions/memory_usage.rb
    lib/god/conditions/process_exits.rb
    lib/god/conditions/process_running.rb
    lib/god/conditions/socket_responding.rb
    lib/god/conditions/tries.rb
    lib/god/configurable.rb
    lib/god/contact.rb
    lib/god/contacts/airbrake.rb
    lib/god/contacts/campfire.rb
    lib/god/contacts/email.rb
    lib/god/contacts/hipchat.rb
    lib/god/contacts/jabber.rb
    lib/god/contacts/prowl.rb
    lib/god/contacts/scout.rb
    lib/god/contacts/sensu.rb
    lib/god/contacts/slack.rb
    lib/god/contacts/statsd.rb
    lib/god/contacts/twitter.rb
    lib/god/contacts/webhook.rb
    lib/god/driver.rb
    lib/god/errors.rb
    lib/god/event_handler.rb
    lib/god/event_handlers/dummy_handler.rb
    lib/god/event_handlers/kqueue_handler.rb
    lib/god/event_handlers/netlink_handler.rb
    lib/god/logger.rb
    lib/god/metric.rb
    lib/god/process.rb
    lib/god/registry.rb
    lib/god/simple_logger.rb
    lib/god/socket.rb
    lib/god/sugar.rb
    lib/god/sys_logger.rb
    lib/god/system/portable_poller.rb
    lib/god/system/process.rb
    lib/god/system/slash_proc_poller.rb
    lib/god/task.rb
    lib/god/timeline.rb
    lib/god/trigger.rb
    lib/god/watch.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
