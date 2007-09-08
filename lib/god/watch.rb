require 'etc'
require 'forwardable'

module God
  
  class Watch
    VALID_STATES = [:init, :up, :start, :restart]
    
    # config
    attr_accessor :state, :interval, :group,
                  :grace, :start_grace, :stop_grace, :restart_grace
    
    
    attr_writer   :autostart
    def autostart?; @autostart; end
    
    extend Forwardable
    def_delegators :@process, :name, :uid, :gid, :start, :stop, :restart,
                              :name=, :uid=, :gid=, :start=, :stop=, :restart=,
                              :pid_file, :pid_file=, :log, :log=, :alive?
    
    # api
    attr_accessor :behaviors, :metrics
    
    # internal
    attr_accessor :mutex
    
    # 
    def initialize
      @autostart ||= true
      @process = God::Process.new
      
      # initial state is unmonitored
      self.state = :unmonitored
      
      # no grace period by default
      self.grace = self.start_grace = self.stop_grace = self.restart_grace = 0
      
      # the list of behaviors
      self.behaviors = []
      
      # the list of conditions for each action
      self.metrics = {nil => [],
                      :unmonitored => [],
                      :init => [],
                      :start => [],
                      :restart => [],
                      :up => []}
      
      # mutex
      self.mutex = Mutex.new
    end
    
    def valid?
      @process.valid?
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
    # Advanced mode
    #
    ###########################################################################
    
    # Define a transition handler which consists of a set of conditions
    def transition(start_states, end_states)
      # convert end_states into canonical hash form
      canonical_end_states = canonical_hash_form(end_states)
      
      Array(start_states).each do |start_state|
        # validate start state
        unless VALID_STATES.include?(start_state)
          abort "Invalid state :#{start_state}. Must be one of the symbols #{VALID_STATES.map{|x| ":#{x}"}.join(', ')}"
        end
        
        # create a new metric to hold the watch, end states, and conditions
        m = Metric.new(self, canonical_end_states)
        
        # let the config file define some conditions on the metric
        yield(m)
        
        # record the metric
        self.metrics[start_state] << m
      end
    end
    
    def lifecycle
      # create a new metric to hold the watch and conditions
      m = Metric.new(self)
      
      # let the config file define some conditions on the metric
      yield(m)
      
      # record the metric
      self.metrics[nil] << m
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
    
    # Disable monitoring
    def unmonitor
      self.move(:unmonitored)
    end
    
    # Move from one state to another
    def move(to_state)
      from_state = self.state
      
      msg = "#{self.name} move '#{from_state}' to '#{to_state}'"
      Syslog.debug(msg)
      LOG.log(self, :info, msg)
      
      # cleanup from current state
      self.metrics[from_state].each { |m| m.disable }
      
      if to_state == :unmonitored
        self.metrics[nil].each { |m| m.disable }
      end
      
      # perform action
      self.action(to_state)
      
      # enable simple mode
      if [:start, :restart].include?(to_state) && self.metrics[to_state].empty?
        to_state = :up
      end
      
      # move to new state
      self.metrics[to_state].each { |m| m.enable }
      
      # if no from state, enable lifecycle metric
      if from_state == :unmonitored
        self.metrics[nil].each { |m| m.enable }
      end
      
      # set state
      self.state = to_state
      
      # trigger
      Trigger.broadcast(:state_change, [from_state, to_state])
      
      # return self
      self
    end
    
    def action(a, c = nil)
      case a
      when :start
        msg = "#{self.name} start: #{self.start.to_s}"
        Syslog.debug(msg)
        LOG.log(self, :info, msg)
        call_action(c, :start)
        sleep(self.start_grace + self.grace)
      when :restart
        if self.restart
          msg = "#{self.name} restart: #{self.restart.to_s}"
          Syslog.debug(msg)
          LOG.log(self, :info, msg)
          call_action(c, :restart)
        else
          action(:stop, c)
          action(:start, c)
        end
        sleep(self.restart_grace + self.grace)
      when :stop
        if self.stop
          msg = "#{self.name} stop: #{self.stop.to_s}"
          Syslog.debug(msg)
          LOG.log(self, :info, msg)
        end
        call_action(c, :stop)
        sleep(self.stop_grace + self.grace)
      end      
    end
    
    def call_action(condition, action)
      # before
      before_items = self.behaviors
      before_items += [condition] if condition
      before_items.each { |b| b.send("before_#{action}") }
      
      @process.call_action(action)

      # after
      after_items = self.behaviors
      after_items += [condition] if condition
      after_items.each { |b| b.send("after_#{action}") }
    end
    
    def canonical_hash_form(to)
      to.instance_of?(Symbol) ? {true => to} : to
    end
    
    def register!
      God.registry.add(@process)
    end
    
    def unregister!
      God.registry.remove(@process)
    end
  end
  
end