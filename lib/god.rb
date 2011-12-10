$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# core
require 'stringio'
require 'fileutils'

begin
  require 'fastthread'
rescue LoadError
ensure
  require 'thread'
end

# stdlib

# internal requires
require 'god/errors'
require 'god/simple_logger'
require 'god/logger'
require 'god/sugar'

require 'god/system/process'
require 'god/system/portable_poller'
require 'god/system/slash_proc_poller'

require 'god/dependency_graph'
require 'god/timeline'
require 'god/configurable'

require 'god/task'

require 'god/behavior'
require 'god/behaviors/clean_pid_file'
require 'god/behaviors/clean_unix_socket'
require 'god/behaviors/notify_when_flapping'

require 'god/condition'
require 'god/conditions/process_running'
require 'god/conditions/process_exits'
require 'god/conditions/tries'
require 'god/conditions/memory_usage'
require 'god/conditions/cpu_usage'
require 'god/conditions/always'
require 'god/conditions/lambda'
require 'god/conditions/degrading_lambda'
require 'god/conditions/flapping'
require 'god/conditions/http_response_code'
require 'god/conditions/disk_usage'
require 'god/conditions/complex'
require 'god/conditions/file_mtime'
require 'god/conditions/socket_responding'

require 'god/socket'
require 'god/driver'

require 'god/metric'
require 'god/watch'

require 'god/trigger'
require 'god/event_handler'
require 'god/registry'
require 'god/process'

require 'god/cli/version'
require 'god/cli/command'

require 'god/diagnostics'

# ruby 1.8 specific configuration
if RUBY_VERSION < '1.9'
  $KCODE = 'u'
end

CONTACT_DEPS = { }
CONTACT_LOAD_SUCCESS = { }

def load_contact(name)
  require "god/contacts/#{name}"
  CONTACT_LOAD_SUCCESS[name] = true
rescue LoadError
  CONTACT_LOAD_SUCCESS[name] = false
end

require 'god/contact'
load_contact(:campfire)
load_contact(:email)
load_contact(:jabber)
load_contact(:prowl)
load_contact(:scout)
load_contact(:twitter)
load_contact(:webhook)

$:.unshift File.join(File.dirname(__FILE__), *%w[.. ext god])

# App wide logging system
LOG = God::Logger.new

def applog(watch, level, text)
  LOG.log(watch, level, text)
end

# The $run global determines whether god should be started when the
# program would normally end. This should be set to true if when god
# should be started (e.g. `god -c <config file>`) and false otherwise
# (e.g. `god status`)
$run ||= nil

GOD_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

# Return the binding of god's root level
def root_binding
  binding
end

module Kernel
  alias_method :abort_orig, :abort
  
  def abort(text = nil)
    $run = false
    applog(nil, :error, text) if text
    exit(1)
  end
  
  alias_method :exit_orig, :exit
  
  def exit(code = 0)
    $run = false
    exit_orig(code)
  end
end

class Module
  def safe_attr_accessor(*args)
    args.each do |arg|
      define_method((arg.to_s + "=").intern) do |other|
        if !self.running && self.inited
          abort "God.#{arg} must be set before any Tasks are defined"
        end
        
        if self.running && self.inited
          applog(nil, :warn, "God.#{arg} can't be set while god is running")
          return
        end
        
        instance_variable_set(('@' + arg.to_s).intern, other)
      end
      
      define_method(arg) do
        instance_variable_get(('@' + arg.to_s).intern)
      end
    end
  end
end

module God
  VERSION = '0.11.0'
  LOG_BUFFER_SIZE_DEFAULT = 100
  PID_FILE_DIRECTORY_DEFAULTS = ['/var/run/god', '~/.god/pids']
  DRB_PORT_DEFAULT = 17165
  DRB_ALLOW_DEFAULT = ['127.0.0.1']
  LOG_LEVEL_DEFAULT = :info
  TERMINATE_TIMEOUT_DEFAULT = 10
  STOP_TIMEOUT_DEFAULT = 10
  STOP_SIGNAL_DEFAULT = 'TERM'
  
  class << self
    # user configurable
    safe_attr_accessor :pid,
                       :host,
                       :port,
                       :allow,
                       :log_buffer_size,
                       :pid_file_directory,
                       :log_file,
                       :log_level,
                       :use_events,
                       :terminate_timeout,
                       :socket_user,
                       :socket_group,
                       :socket_perms
    
    # internal
    attr_accessor :inited,
                  :running,
                  :pending_watches,
                  :pending_watch_states,
                  :server,
                  :watches,
                  :groups,
                  :contacts,
                  :contact_groups,
                  :main
  end
  
  # initialize class instance variables
  self.pid = nil
  self.host = nil
  self.port = nil
  self.allow = nil
  self.log_buffer_size = nil
  self.pid_file_directory = nil
  self.log_level = nil
  self.terminate_timeout = nil
  self.socket_user = nil
  self.socket_group = nil
  self.socket_perms = 0755
  
  # Initialize internal data.
  #
  # Returns nothing
  def self.internal_init
    # only do this once
    return if self.inited
    
    # variable init
    self.watches = {}
    self.groups = {}
    self.pending_watches = []
    self.pending_watch_states = {}
    self.contacts = {}
    self.contact_groups = {}
    
    # set defaults
    self.log_buffer_size ||= LOG_BUFFER_SIZE_DEFAULT
    self.port ||= DRB_PORT_DEFAULT
    self.allow ||= DRB_ALLOW_DEFAULT
    self.log_level ||= LOG_LEVEL_DEFAULT
    self.terminate_timeout ||= TERMINATE_TIMEOUT_DEFAULT
    
    # additional setup
    self.setup
    
    # log level
    log_level_map = {:debug => Logger::DEBUG,
                     :info => Logger::INFO,
                     :warn => Logger::WARN,
                     :error => Logger::ERROR,
                     :fatal => Logger::FATAL}
    LOG.level = log_level_map[self.log_level]
    
    # init has been executed
    self.inited = true
    
    # not yet running
    self.running = false
  end
  
  # Instantiate a new, empty Watch object and pass it to the mandatory
  # block. The attributes of the watch will be set by the configuration
  # file.
  #
  # Aborts on duplicate watch name
  #           invalid watch
  #           conflicting group name
  #
  # Returns nothing
  def self.watch(&block)
    self.task(Watch, &block)
  end
  
  # Instantiate a new, empty Task object and yield it to the mandatory
  # block. The attributes of the task will be set by the configuration
  # file.
  #
  # Aborts on duplicate task name
  #           invalid task
  #           conflicting group name
  #
  # Returns nothing
  def self.task(klass = Task)
    self.internal_init
    
    t = klass.new
    yield(t)
    
    # do the post-configuration
    t.prepare
    
    # if running, completely remove the watch (if necessary) to
    # prepare for the reload
    existing_watch = self.watches[t.name]
    if self.running && existing_watch
      self.pending_watch_states[existing_watch.name] = existing_watch.state
      self.unwatch(existing_watch)
    end
    
    # ensure the new watch has a unique name
    if self.watches[t.name] || self.groups[t.name]
      abort "Task name '#{t.name}' already used for a Task or Group"
    end
    
    # ensure watch is internally valid
    t.valid? || abort("Task '#{t.name}' is not valid (see above)")
    
    # add to list of watches
    self.watches[t.name] = t
    
    # add to pending watches
    self.pending_watches << t
    
    # add to group if specified
    if t.group
      # ensure group name hasn't been used for a watch already
      if self.watches[t.group]
        abort "Group name '#{t.group}' already used for a Task"
      end
      
      self.groups[t.group] ||= []
      self.groups[t.group] << t
    end
    
    # register watch
    t.register!
    
    # log
    if self.running && existing_watch
      applog(t, :info, "#{t.name} Reloaded config")
    elsif self.running
      applog(t, :info, "#{t.name} Loaded config")
    end
  end
  
  # Unmonitor and remove the given watch from god.
  #   +watch+ is the Watch to remove
  #
  # Returns nothing
  def self.unwatch(watch)
    # unmonitor
    watch.unmonitor unless watch.state == :unmonitored
    
    # unregister
    watch.unregister!
    
    # remove from watches
    self.watches.delete(watch.name)
    
    # remove from groups
    if watch.group
      self.groups[watch.group].delete(watch)
    end
    
    applog(watch, :info, "#{watch.name} unwatched")
  end
  
  # Instantiate a new Contact of the given kind and send it to the block.
  # Then prepare, validate, and record the Contact.
  #   +kind+ is the contact class specifier
  #
  # Aborts on invalid kind
  #           duplicate contact name
  #           invalid contact
  #           conflicting group name
  #
  # Returns nothing
  def self.contact(kind)
    self.internal_init
    
    # verify contact has been loaded
    if CONTACT_LOAD_SUCCESS[kind] == false
      applog(nil, :error, "A required dependency for the #{kind} contact is unavailable.")
      applog(nil, :error, "Run the following commands to install the dependencies:")
      CONTACT_DEPS[kind].each do |d|
        applog(nil, :error, "  [sudo] gem install #{d}")
      end
      abort
    end
    
    # create the contact
    begin
      c = Contact.generate(kind)
    rescue NoSuchContactError => e
      abort e.message
    end
    
    # send to block so config can set attributes
    yield(c) if block_given?
    
    # call prepare on the contact
    c.prepare
    
    # remove existing contacts of same name
    existing_contact = self.contacts[c.name]
    if self.running && existing_contact
      self.uncontact(existing_contact)
    end
    
    # warn and noop if the contact has been defined before
    if self.contacts[c.name] || self.contact_groups[c.name]
      applog(nil, :warn, "Contact name '#{c.name}' already used for a Contact or Contact Group")
      return
    end
    
    # abort if the Contact is invalid, the Contact will have printed
    # out its own error messages by now
    unless Contact.valid?(c) && c.valid?
      abort "Exiting on invalid contact"
    end
    
    # add to list of contacts
    self.contacts[c.name] = c
    
    # add to contact group if specified
    if c.group
      # ensure group name hasn't been used for a contact already
      if self.contacts[c.group]
        abort "Contact Group name '#{c.group}' already used for a Contact"
      end
      
      self.contact_groups[c.group] ||= []
      self.contact_groups[c.group] << c
    end
  end
  
  # Remove the given contact from god.
  #   +contact+ is the Contact to remove
  #
  # Returns nothing
  def self.uncontact(contact)
    self.contacts.delete(contact.name)
    if contact.group
      self.contact_groups[contact.group].delete(contact)
    end
  end
  
  # Control the lifecycle of the given task(s).
  #   +name+ is the name of a task/group (String)
  #   +command+ is the command to run (String)
  #             one of: "start"
  #                     "monitor"
  #                     "restart"
  #                     "stop"
  #                     "unmonitor"
  #                     "remove"
  #
  # Returns String[]:task_names
  def self.control(name, command)
    # get the list of items
    items = Array(self.watches[name] || self.groups[name]).dup
    
    jobs = []
    
    # do the command
    case command
      when "start", "monitor"
        items.each { |w| jobs << Thread.new { w.monitor if w.state != :up } }
      when "restart"
        items.each { |w| jobs << Thread.new { w.move(:restart) } }
      when "stop"
        items.each { |w| jobs << Thread.new { w.action(:stop); w.unmonitor if w.state != :unmonitored } }
      when "unmonitor"
        items.each { |w| jobs << Thread.new { w.unmonitor if w.state != :unmonitored } }
      when "remove"
        items.each { |w| self.unwatch(w) }
      else
        raise InvalidCommandError.new
    end
    
    jobs.each { |j| j.join }
    
    items.map { |x| x.name }
  end
  
  # Unmonitor and stop all tasks.
  #
  # Returns true on success
  #         false if all tasks could not be stopped within 10 seconds
  def self.stop_all
    self.watches.sort.each do |name, w|
      Thread.new do
        w.unmonitor if w.state != :unmonitored
        w.action(:stop) if w.alive?
      end
    end
    
    terminate_timeout.times do
      return true unless self.watches.map { |name, w| w.alive? }.any?
      sleep 1
    end
    
    return false
  end
  
  # Force the termination of god.
  #   * Clean up pid file if one exists
  #   * Stop DRb service
  #   * Hard exit using exit!
  #
  # Never returns because the process will no longer exist!
  def self.terminate
    FileUtils.rm_f(self.pid) if self.pid
    self.server.stop if self.server
    exit!(0)
  end
  
  # Gather the status of each task.
  #
  # Examples
  #   God.status
  #   # => { 'mongrel' => :up, 'nginx' => :up }
  #
  # Returns { String:task_name => Symbol:status, ... }
  def self.status
    info = {}
    self.watches.map do |name, w|
      info[name] = {:state => w.state, :group => w.group}
    end
    info
  end
  
  # Send a signal to each task.
  #   +name+ is the String name of the task or group
  #   +signal+ is the signal to send. e.g. HUP, 9
  #
  # Returns String[]:task_names
  def self.signal(name, signal)
    items = Array(self.watches[name] || self.groups[name]).dup
    jobs = []
    items.each { |w| jobs << Thread.new { w.signal(signal) } }
    jobs.each { |j| j.join }
    items.map { |x| x.name }
  end
  
  # Log lines for the given task since the specified time.
  #   +watch_name+ is the name of the task (may be abbreviated)
  #   +since+ is the Time since which to report log lines
  #
  # Raises God::NoSuchWatchError if no tasks matched
  #
  # Returns String:joined_log_lines
  def self.running_log(watch_name, since)
    matches = pattern_match(watch_name, self.watches.keys)
    
    unless matches.first
      raise NoSuchWatchError.new
    end
    
    LOG.watch_log_since(matches.first, since)
  end
  
  # Load a config file into a running god instance. Rescues any exceptions
  # that the config may raise and reports these back to the caller.
  #   +code+ is a String containing the config file
  #   +filename+ is the filename of the config file
  #
  # Returns [String[]:task_names, String:errors]
  def self.running_load(code, filename)
    errors = ""
    watches = []
    
    begin
      LOG.start_capture
      
      Gem.clear_paths
      eval(code, root_binding, filename)
      self.pending_watches.each do |w|
        if previous_state = self.pending_watch_states[w.name]
          w.monitor unless previous_state == :unmonitored
        else
          w.monitor if w.autostart?
        end
      end
      watches = self.pending_watches.dup
      self.pending_watches.clear
      self.pending_watch_states.clear

      # make sure we quit capturing when we're done
      LOG.finish_capture
    rescue Exception => e
      # don't ever let running_load take down god
      errors << LOG.finish_capture
      
      unless e.instance_of?(SystemExit)
        errors << e.message << "\n"
        errors << e.backtrace.join("\n")
      end
    end
    
    names = watches.map { |x| x.name }
    [names, errors]
  end
  
  # Load the given file(s) according to the given glob.
  #   +glob+ is the glob-enabled path to load
  #
  # Returns nothing
  def self.load(glob)
    Dir[glob].each do |f|
      Kernel.load f
    end
  end
  
  def self.setup
    if self.pid_file_directory
      # pid file dir was specified, ensure it is created and writable
      unless File.exist?(self.pid_file_directory)
        begin
          FileUtils.mkdir_p(self.pid_file_directory)
        rescue Errno::EACCES => e
          abort "Failed to create pid file directory: #{e.message}"
        end
      end
      
      unless File.writable?(self.pid_file_directory)
        abort "The pid file directory (#{self.pid_file_directory}) is not writable by #{Etc.getlogin}"
      end
    else
      # no pid file dir specified, try defaults
      PID_FILE_DIRECTORY_DEFAULTS.each do |idir|
        dir = File.expand_path(idir)
        begin
          FileUtils.mkdir_p(dir)
          if File.writable?(dir)
            self.pid_file_directory = dir
            break
          end
        rescue Errno::EACCES => e
        end
      end
      
      unless self.pid_file_directory
        dirs = PID_FILE_DIRECTORY_DEFAULTS.map { |x| File.expand_path(x) }
        abort "No pid file directory exists, could be created, or is writable at any of #{dirs.join(', ')}"
      end
    end
    
    if God::Logger.syslog
      LOG.info("Syslog enabled.")
    else
      LOG.info("Syslog disabled.")
    end
    
    applog(nil, :info, "Using pid file directory: #{self.pid_file_directory}")
  end
  
  # Initialize and startup the machinery that makes god work.
  #
  # Returns nothing
  def self.start
    self.internal_init
    
    # instantiate server
    self.server = Socket.new(self.port, self.socket_user, self.socket_group, self.socket_perms)
    
    # start monitoring any watches set to autostart
    self.watches.values.each { |w| w.monitor if w.autostart? }
    
    # clear pending watches
    self.pending_watches.clear
    
    # mark as running
    self.running = true
    
    # don't exit
    self.main = 
    Thread.new do
      loop do
        sleep 60
      end
    end
    
    self.main.join
  end
  
  def self.version
    God::VERSION
  end
  
  # To be called on program exit to start god
  #
  # Returns nothing
  def self.at_exit
    self.start
  end
  
  # private
  
  # Match a shortened pattern against a list of String candidates.
  # The pattern is expanded into a regular expression by
  # inserting .* between each character.
  #   +pattern+ is the String containing the abbreviation
  #   +list+ is the Array of Strings to match against
  #
  # Examples
  #
  #   list = %w{ foo bar bars }
  #   pattern = 'br'
  #   God.pattern_match(list, pattern)
  #   # => ['bar', 'bars']
  #
  # Returns String[]:matched_elements
  def self.pattern_match(pattern, list)
    regex = pattern.split('').join('.*')
    
    list.select do |item|
      item =~ Regexp.new(regex)
    end.sort_by { |x| x.size }
  end
end

# Runs immediately before the program exits. If $run is true,
# start god, if $run is false, exit normally.
#
# Returns nothing
at_exit do
  God.at_exit if $run
end
