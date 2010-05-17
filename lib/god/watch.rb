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
                              :stop_signal=
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
