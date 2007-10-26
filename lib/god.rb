$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# core
require 'stringio'
require 'logger'

# stdlib
require 'syslog'

# internal requires
require 'god/errors'
require 'god/logger'
require 'god/system/process'
require 'god/dependency_graph'
require 'god/timeline'
require 'god/configurable'

require 'god/task'

require 'god/behavior'
require 'god/behaviors/clean_pid_file'
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

require 'god/contact'
require 'god/contacts/email'

require 'god/socket'
require 'god/timer'
require 'god/hub'

require 'god/metric'
require 'god/watch'

require 'god/trigger'
require 'god/event_handler'
require 'god/registry'
require 'god/process'

require 'god/sugar'

$:.unshift File.join(File.dirname(__FILE__), *%w[.. ext god])

# App wide logging system
LOG = God::Logger.new
LOG.datetime_format = "%Y-%m-%d %H:%M:%S "

def applog(watch, level, text)
  LOG.log(watch, level, text)
end

# The $run global determines whether god should be started when the
# program would normally end. This should be set to true if when god
# should be started (e.g. `god -c <config file>`) and false otherwise
# (e.g. `god status`)
$run ||= nil

GOD_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

# Ensure that Syslog is open
begin
  Syslog.open('god')
rescue RuntimeError
  Syslog.reopen('god')
end

# Return the binding of god's root level
def root_binding
  binding
end

# Load the event handler system
God::EventHandler.load

module Kernel
  alias_method :abort_orig, :abort
  
  def abort(text = nil)
    $run = false
    applog(nil, :error, text) if text
    # text ? abort_orig(text) : exit(1)
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
  VERSION = '0.5.2'
  
  LOG_BUFFER_SIZE_DEFAULT = 1000
  PID_FILE_DIRECTORY_DEFAULT = '/var/run/god'
  DRB_PORT_DEFAULT = 17165
  DRB_ALLOW_DEFAULT = ['127.0.0.1']
  
  class << self
    # user configurable
    safe_attr_accessor :pid,
                       :host,
                       :port,
                       :allow,
                       :log_buffer_size,
                       :pid_file_directory
    
    # internal
    attr_accessor :inited,
                  :running,
                  :pending_watches,
                  :pending_watch_states,
                  :server,
                  :watches,
                  :groups,
                  :contacts,
                  :contact_groups
  end
  
  # initialize class instance variables
  self.pid = nil
  self.host = nil
  self.port = nil
  self.allow = nil
  self.log_buffer_size = nil
  self.pid_file_directory = nil
  
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
    self.pid_file_directory ||= PID_FILE_DIRECTORY_DEFAULT
    self.port ||= DRB_PORT_DEFAULT
    self.allow ||= DRB_ALLOW_DEFAULT
    LOG.level = Logger::INFO
    
    # init has been executed
    self.inited = true
    
    # not yet running
    self.running = false
  end
  
  # Instantiate a new, empty Watch object and pass it to the mandatory
  # block. The attributes of the watch will be set by the configuration
  # file.
  def self.watch(&block)
    self.task(Watch, &block)
  end
  
  # Instantiate a new, empty Task object and pass it to the mandatory
  # block. The attributes of the task will be set by the configuration
  # file.
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
  end
  
  def self.contact(kind)
    self.internal_init
    
    # create the condition
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
    
    # ensure the new contact has a unique name
    if self.contacts[c.name] || self.contact_groups[c.name]
      abort "Contact name '#{c.name}' already used for a Contact or Contact Group"
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
  
  def self.uncontact(contact)
    self.contacts.delete(contact.name)
    if contact.group
      self.contact_groups[contact.group].delete(contact)
    end
  end
    
  def self.control(name, command)
    # get the list of watches
    watches = Array(self.watches[name] || self.groups[name])
    
    jobs = []
    
    # do the command
    case command
      when "start", "monitor"
        watches.each { |w| jobs << Thread.new { w.monitor if w.state != :up } }
      when "restart"
        watches.each { |w| jobs << Thread.new { w.move(:restart) } }
      when "stop"
        watches.each { |w| jobs << Thread.new { w.unmonitor.action(:stop) if w.state != :unmonitored } }
      when "unmonitor"
        watches.each { |w| jobs << Thread.new { w.unmonitor if w.state != :unmonitored } }
      else
        raise InvalidCommandError.new
    end
    
    jobs.each { |j| j.join }
    
    watches.map { |x| x.name }
  end
  
  def self.stop_all
    self.watches.sort.each do |name, w|
      Thread.new do
        w.unmonitor if w.state != :unmonitored
        w.action(:stop) if w.alive?
      end
    end
    
    10.times do
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
  
  def self.status
    info = {}
    self.watches.map do |name, w|
      info[name] = {:state => w.state}
    end
    info
  end
  
  def self.running_log(watch_name, since)
    unless self.watches[watch_name]
      raise NoSuchWatchError.new
    end
    
    LOG.watch_log_since(watch_name, since)
  end
  
  def self.running_load(code, filename)
    errors = ""
    watches = []
    
    begin
      LOG.start_capture
      
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
  
  def self.load(glob)
    Dir[glob].each do |f|
      Kernel.load f
    end
  end
  
  def self.setup
    # Make pid directory
    unless test(?d, self.pid_file_directory)
      begin
        FileUtils.mkdir_p(self.pid_file_directory)
      rescue Errno::EACCES => e
        abort "Failed to create pid file directory: #{e.message}"
      end
    end
  end
  
  def self.validater
    unless test(?w, self.pid_file_directory)
      abort "The pid file directory (#{self.pid_file_directory}) is not writable by #{Etc.getlogin}"
    end
  end
  
  def self.start
    self.internal_init
    self.setup
    self.validater
    
    # instantiate server
    self.server = Socket.new(self.port)
    
    # start event handler system
    EventHandler.start if EventHandler.loaded?
    
    # start the timer system
    Timer.get
    
    # start monitoring any watches set to autostart
    self.watches.values.each { |w| w.monitor if w.autostart? }
    
    # clear pending watches
    self.pending_watches.clear
    
    # mark as running
    self.running = true
    
    # join the timer thread so we don't exit
    Timer.get.join
  end
  
  def self.at_exit
    self.start
  end
end

at_exit do
  God.at_exit if $run
end