$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# core
require 'logger'

# stdlib
require 'syslog'

# internal requires
require 'god/errors'
require 'god/logger'
require 'god/system/process'
require 'god/dependency_graph'
require 'god/timeline'

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

require 'god/reporter'
require 'god/server'
require 'god/timer'
require 'god/hub'

require 'god/metric'
require 'god/watch'

require 'god/event_handler'
require 'god/registry'
require 'god/process'

require 'god/sugar'

$:.unshift File.join(File.dirname(__FILE__), *%w[.. ext god])

begin
  Syslog.open('god')
rescue RuntimeError
  Syslog.reopen('god')
end

God::EventHandler.load

module God
  VERSION = '0.4.0'
  
  LOG = Logger.new
    
  LOG_BUFFER_SIZE_DEFAULT = 100
  PID_FILE_DIRECTORY_DEFAULT = '/var/run/god'
  DRB_PORT_DEFAULT = 17165
  DRB_ALLOW_DEFAULT = ['127.0.0.1']
  
  class << self
    # user configurable
    attr_accessor :host,
                  :port,
                  :allow,
                  :log_buffer_size,
                  :pid_file_directory
    
    # internal
    attr_accessor :inited,
                  :running,
                  :pending_watches,
                  :server,
                  :watches,
                  :groups
  end
  
  def self.init
    if self.inited
      abort "God.init must be called before any Watches"
    end
    
    self.internal_init
  end
  
  def self.internal_init
    # only do this once
    return if self.inited
    
    # variable init
    self.watches = {}
    self.groups = {}
    self.pending_watches = []
    
    # set defaults
    self.log_buffer_size = LOG_BUFFER_SIZE_DEFAULT
    self.pid_file_directory = PID_FILE_DIRECTORY_DEFAULT
    self.port = DRB_PORT_DEFAULT
    self.allow = DRB_ALLOW_DEFAULT
    
    # yield to the config file
    yield self if block_given?
    
    # init has been executed
    self.inited = true
    
    # not yet running
    self.running = false
  end
    
  # Instantiate a new, empty Watch object and pass it to the mandatory
  # block. The attributes of the watch will be set by the configuration
  # file.
  def self.watch
    self.internal_init
    
    w = Watch.new
    yield(w)
    
    # if running, completely remove the watch (if necessary) to
    # prepare for the reload
    existing_watch = self.watches[w.name]
    if self.running && existing_watch
      self.unwatch(existing_watch)
    end
    
    # ensure the new watch has a unique name
    if self.watches[w.name] || self.groups[w.name]
      abort "Watch name '#{w.name}' already used for a Watch or Group"
    end
    
    # ensure watch is internally valid
    w.valid? || abort("Watch '#{w.name}' is not valid (see above)")
    
    # add to list of watches
    self.watches[w.name] = w
    
    # add to pending watches
    self.pending_watches << w
    
    # add to group if specified
    if w.group
      # ensure group name hasn't been used for a watch already
      if self.watches[w.group]
        abort "Group name '#{w.group}' already used for a Watch"
      end
    
      self.groups[w.group] ||= []
      self.groups[w.group] << w
    end

    # register watch
    w.register!
  end
  
  def self.unwatch(watch)
    # unmonitor
    watch.unmonitor
    
    # unregister
    watch.unregister!
    
    # remove from watches
    self.watches.delete(watch.name)
    
    # remove from groups
    if watch.group
      self.groups[watch.group].delete(watch)
    end
  end
    
  def self.control(name, command)
    # get the list of watches
    watches = Array(self.watches[name] || self.groups[name])
  
    # do the command
    case command
      when "start", "monitor"
        watches.each { |w| w.monitor }
      when "restart"
        watches.each { |w| w.move(:restart) }
      when "stop"
        watches.each { |w| w.unmonitor.action(:stop) }
      when "unmonitor"
        watches.each { |w| w.unmonitor }
      else
        raise InvalidCommandError.new
    end
    
    watches
  end
  
  def self.stop_all
    self.watches.each do |name, w|
      w.unmonitor if w.state
      w.action(:stop) if w.alive?
    end
    
    10.times do
      return true unless self.watches.map { |name, w| w.alive? }.any?
      sleep 1
    end
    
    return false
  end
  
  def self.terminate
    exit!(0)
  end
  
  def self.status
    info = {}
    self.watches.map do |name, w|
      status = w.state || :unmonitored
      info[name] = {:state => status}
    end
    info
  end
  
  def self.running_log(watch_name, since)
    unless self.watches[watch_name]
      raise NoSuchWatchError.new
    end
    
    LOG.watch_log_since(watch_name, since)
  end
  
  def self.running_load(code)
    eval(code)
    self.pending_watches.each { |w| w.monitor if w.autostart? }
    watches = self.pending_watches.dup
    self.pending_watches.clear
    watches
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
    self.server = Server.new(self.host, self.port, self.allow)
    
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
  God.at_exit
end