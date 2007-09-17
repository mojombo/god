module God
  
  class Task
    attr_accessor :name, :interval, :group, :valid_states, :initial_state
    
    attr_writer   :autostart
    def autostart?; @autostart; end
    
    # api
    attr_accessor :state, :behaviors, :metrics
    
    # internal
    attr_accessor :mutex
    
    def initialize
      @autostart ||= true
      
      # initial state is unmonitored
      self.state = :unmonitored
      
      # the list of behaviors
      self.behaviors = []
      
      # the list of conditions for each action
      self.metrics = {nil => [], :unmonitored => []}
      
      # mutex
      self.mutex = Mutex.new
    end
    
    def prepare
      self.valid_states.each do |state|
        self.metrics[state] ||= []
      end
    end
    
    def valid?
      true
    end
    
    ###########################################################################
    #
    # Advanced mode
    #
    ###########################################################################
    
    def canonical_hash_form(to)
      to.instance_of?(Symbol) ? {true => to} : to
    end
    
    # Define a transition handler which consists of a set of conditions
    def transition(start_states, end_states)
      # convert end_states into canonical hash form
      canonical_end_states = canonical_hash_form(end_states)
      
      Array(start_states).each do |start_state|
        # validate start state
        unless self.valid_states.include?(start_state)
          abort "Invalid state :#{start_state}. Must be one of the symbols #{self.valid_states.map{|x| ":#{x}"}.join(', ')}"
        end
        
        # create a new metric to hold the watch, end states, and conditions
        m = Metric.new(self, canonical_end_states)
        
        if block_given?
          # let the config file define some conditions on the metric
          yield(m)
        else
          # add an :always condition if no block
          m.condition(:always) do |c|
            c.what = true
          end
        end
        
        # record the metric
        self.metrics[start_state] ||= []
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
    # Lifecycle
    #
    ###########################################################################
        
    # Enable monitoring
    def monitor
      self.move(self.initial_state)
    end
    
    # Disable monitoring
    def unmonitor
      self.move(:unmonitored)
    end
    
    # Move from one state to another
    def move(to_state)
      orig_to_state = to_state
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
      Trigger.broadcast(:state_change, [from_state, orig_to_state])
      
      # return self
      self
    end
    
    ###########################################################################
    #
    # Actions
    #
    ###########################################################################
    
    def method_missing(sym, *args)
      unless (sym.to_s =~ /=$/)
        super
      end
      
      base = sym.to_s.chop.intern
      
      unless self.valid_states.include?(base)
        super
      end
      
      self.class.send(:attr_accessor, base)
      self.send(sym, *args)
    end
    
    #   +a+ is the action Symbol
    #   +c+ is the Condition
    def action(a, c = nil)
      if self.respond_to?(a)
        command = self.send(a)
        
        case command
          when String
            msg = "#{self.name} #{a}: #{command}"
            Syslog.debug(msg)
            LOG.log(self, :info, msg)
            
            system(command)
          when Proc
            msg = "#{self.name} #{a}: lambda"
            Syslog.debug(msg)
            LOG.log(self, :info, msg)
            
            command.call
          else
            raise NotImplementedError
        end
      end
    end
    
    ###########################################################################
    #
    # Registration
    #
    ###########################################################################
    
    def register!
      # override if necessary
    end
    
    def unregister!
      # override if necessary
    end
  end
  
end