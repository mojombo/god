module God
  
  class Watch < Base
    # config
    attr_accessor :name, :start, :stop, :restart, :interval, :grace
    
    # api
    attr_accessor :behaviors, :conditions
    
    # internal
    attr_accessor :mutex
    
    # 
    def initialize(meddle)
      @meddle = meddle
      
      # no grace period by default
      self.grace = 0
      
      # keep track of which action each condition belongs to
      @action = nil
      
      self.behaviors = []
      
      # the list of conditions for each action
      self.conditions = {:start => [],
                         :restart => []}
                         
      # mutex
      self.mutex = Mutex.new
    end
    
    def behavior(kind)
      # create the behavior
      begin
        b = Behavior.generate(kind)
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
    
    def start_if
      @action = :start
      yield(self)
      @action = nil
    end
    
    def restart_if
      @action = :restart
      yield(self)
      @action = nil
    end
    
    # Instantiate a Condition of type +kind+ and pass it into the optional
    # block. Attributes of the condition must be set in the config file
    def condition(kind)
      # must be in a _if block
      unless @action
        abort "Watch#condition can only be called from inside a start_if block"
      end
      
      # create the condition
      begin
        c = Condition.generate(kind)
      rescue NoSuchConditionError => e
        abort e.message
      end
      
      # send to block so config can set attributes
      yield(c) if block_given?
      
      # call prepare on the condition
      c.prepare
      
      # abort if the Condition is invalid, the Condition will have printed
      # out its own error messages by now
      unless c.valid?
        abort
      end
      
      # inherit interval from meddle if no poll condition specific interval was set
      if c.kind_of?(PollCondition) && !c.interval
        if self.interval
          c.interval = self.interval
        else
          abort "No interval set for Condition '#{c.class.name}' in Watch '#{self.name}', and no default Watch interval from which to inherit"
        end
      end
      
      self.conditions[@action] << c
    end
    
    # Define a transition handler which consists of a set of conditions
    def transition(from, to)
      
    end
        
    # Schedule all poll conditions and register all condition events
    def monitor
      [:start, :restart].each do |cmd|
        self.conditions[cmd].each do |c|
          @meddle.timer.register(self, c, cmd) if c.kind_of?(PollCondition)
          c.register(self) if c.kind_of?(EventCondition)
        end
      end
    end
    
    def action(a, c)
      case a
      when :start
        puts self.start
        call_action(c, :start, self.start)
        sleep(self.grace)
      when :restart
        if self.restart
          puts self.restart
          call_action(c, :restart, self.restart)
        else
          action(:stop, c)
          action(:start, c)
        end
        sleep(self.grace)
      when :stop
        puts self.stop
        call_action(c, :stop, self.stop)
        sleep(self.grace)
      end      
    end
    
    def call_action(condition, action, command)
      # before
      (self.behaviors + [condition]).each { |b| b.send("before_#{action}") }
      
      # action
      if command.kind_of?(String)
        # string command
        system(command)
      else
        # lambda command
        command.call
      end
      
      # after
      (self.behaviors + [condition]).each { |b| b.send("after_#{action}") }
    end
  end
  
end