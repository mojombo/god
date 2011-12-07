require 'etc'
require 'forwardable'

module God
  
  class Watch < Task
    VALID_STATES = [:init, :up, :start, :restart]
    INITIAL_STATE = :init
    
    # config
    attr_accessor :grace, :start_grace, :stop_grace, :restart_grace
    
    extend Forwardable
    def_delegators :@process, :name, :uid, :gid, :start, :stop, :restart, :dir,
                              :name=, :uid=, :gid=, :start=, :stop=, :restart=,
                              :dir=, :pid_file, :pid_file=, :log, :log=,
                              :log_cmd, :log_cmd=, :err_log, :err_log=,
                              :err_log_cmd, :err_log_cmd=, :alive?, :pid,
                              :unix_socket, :unix_socket=, :chroot, :chroot=,
                              :env, :env=, :signal, :stop_timeout=,
                              :stop_signal=, :umask, :umask=
    # 
    def initialize
      super
      
      @process = God::Process.new
      
      # valid states
      self.valid_states = VALID_STATES
      self.initial_state = INITIAL_STATE
      
      # no grace period by default
      self.grace = self.start_grace = self.stop_grace = self.restart_grace = 0
    end
    
    def valid?
      super && @process.valid?
    end
    
    ###########################################################################
    #
    # Behavior
    #
    ###########################################################################
    
    def behavior(kind)
      # create the behavior
      begin
        b = Behavior.generate(kind, self)
      rescue NoSuchBehaviorError => e
        abort e.message
      end
      
      # send to block so config can set attributes
      yield(b) if block_given?
      
      # abort if the Behavior is invalid, the Behavior will have printed
      # out its own error messages by now
      abort unless b.valid?
      
      self.behaviors << b
    end
    
    ###########################################################################
    #
    # Quickstart mode
    #
    ###########################################################################
    
    DEFAULT_KEEPALIVE_INTERVAL = 5.seconds
    DEFAULT_KEEPALIVE_MEMORY_TIMES = [3, 5]
    DEFAULT_KEEPALIVE_CPU_TIMES = [3, 5]
    
    # A set of conditions for easily getting started with simple watch
    # scenarios. Keepalive is intended for use by beginners or on processes
    # that do not need very sophisticated monitoring.
    #
    # If events are enabled, it will use the :process_exit event to determine
    # if a process fails. Otherwise it will use the :process_running poll.
    #
    # options - The option Hash. Possible values are:
    #           :interval -     The Integer number of seconds on which to poll
    #                           for process status. Affects CPU, memory, and
    #                           :process_running conditions (if used).
    #           :memory_max   - The Integer memory max
    #           :memory_times - If :memory_max is set, :memory_times can be
    #                           set to specify the 
    def keepalive(options = {})
      self.start_if do |start|
        start.condition(:process_running) do |c|
          c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
          c.running = false
        end
      end
      
      self.restart_if do |restart|
        if options[:memory_max]
          restart.condition(:memory_usage) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.above = options[:memory_max]
            c.times = options[:memory_times] || DEFAULT_KEEPALIVE_MEMORY_TIMES
          end
        end
        
        if options[:cpu_max]
          restart.condition(:cpu_usage) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.above = options[:cpu_max]
            c.times = options[:cpu_times] || DEFAULT_KEEPALIVE_CPU_TIMES
          end
        end
      end
    end
    
    ###########################################################################
    #
    # Simple mode
    #
    ###########################################################################
    
    def start_if
      self.transition(:up, :start) do |on|
        yield(on)
      end
    end
    
    def restart_if
      self.transition(:up, :restart) do |on|
        yield(on)
      end
    end
    
    def stop_if 
      self.transition(:up, :stop) do |on| 
        yield(on) 
      end 
    end
    
    ###########################################################################
    #
    # Lifecycle
    #
    ###########################################################################
    
    # Enable monitoring
    def monitor
      # start monitoring at the first available of the init or up states
      if !self.metrics[:init].empty?
        self.move(:init)
      else
        self.move(:up)
      end
    end
    
    ###########################################################################
    #
    # Actions
    #
    ###########################################################################
    
    def action(a, c = nil)
      if !self.driver.in_driver_context?
        # called from outside Driver
        
        # send an async message to Driver
        self.driver.message(:action, [a, c])
      else
        # called from within Driver
        
        case a
        when :start
          call_action(c, :start)
          sleep(self.start_grace + self.grace)
        when :restart
          if self.restart
            call_action(c, :restart)
          else
            action(:stop, c)
            action(:start, c)
          end
          sleep(self.restart_grace + self.grace)
        when :stop
          call_action(c, :stop)
          sleep(self.stop_grace + self.grace)
        end
      end
      
      self
    end
    
    def call_action(condition, action)
      # before
      before_items = self.behaviors
      before_items += [condition] if condition
      before_items.each do |b|
        info = b.send("before_#{action}")
        if info
          msg = "#{self.name} before_#{action}: #{info} (#{b.base_name})"
          applog(self, :info, msg)
        end
      end
      
      # log
      if self.send(action)
        msg = "#{self.name} #{action}: #{self.send(action).to_s}"
        applog(self, :info, msg)
      end
      
      @process.call_action(action)
      
      # after
      after_items = self.behaviors
      after_items += [condition] if condition
      after_items.each do |b|
        info = b.send("after_#{action}")
        if info
          msg = "#{self.name} after_#{action}: #{info} (#{b.base_name})"
          applog(self, :info, msg)
        end
      end
    end
    
    ###########################################################################
    #
    # Registration
    #
    ###########################################################################
    
    def register!
      God.registry.add(@process)
    end
    
    def unregister!
      God.registry.remove(@process)
      super
    end
  end
  
end
