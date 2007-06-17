module God
  
  class Watch < Base
    # config
    attr_accessor :name, :cwd, :start, :stop, :restart, :grace
    
    # api
    attr_accessor :conditions
    
    # 
    def initialize
      # no grace period by default
      self.grace = 0
      
      # keep track of which action each condition belongs to
      @action = nil
      
      # the list of conditions for each action
      self.conditions = {:start => [],
                         :restart => []}
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
        puts "Watch#condition can only be called from inside a start_if block"
        exit
      end
      
      # create the condition
      begin
        c = Condition.generate(kind)
      rescue NoSuchConditionError => e
        puts e.message
        exit
      end
      
      # send to block so config can set attributes
      yield(c) if block_given?
      
      # call prepare on the condition
      c.prepare
      
      # exit if the Condition is invalid, the Condition will have printed
      # out its own error messages by now
      unless c.valid?
        exit
      end
      
      self.conditions[@action] << c
    end
    
    def run
      [:start, :restart].each do |cmd|
        self.conditions[cmd].each do |c|
          if c.test
            puts self.name + ' ' + c.class.name + ' [ok]'
          else
            puts self.name + ' ' + c.class.name + ' [fail]'
            c.after
            action(cmd, c)
            return
          end
        end
      end
    end
    
    private
    
    def action(a, c)
      case a
      when :start
        puts self.start
        Dir.chdir(self.cwd) do
          c.before_start
          call_action(self.start)
          c.after_start
        end
        sleep(self.grace)
      when :restart
        if self.restart
          puts self.restart
          Dir.chdir(self.cwd) do
            c.before_restart
            call_action(self.restart)
            c.after_restart
          end
        else
          self.action(:stop, c)
          self.action(:start, c)
        end
        sleep(self.grace)
      when :stop
        puts self.stop
        Dir.chdir(self.cwd) do
          c.before_stop
          call_action(self.stop)
          c.after_stop
        end
        sleep(self.grace)
      end      
    end
    
    def call_action(action)
      if action.kind_of?(String)
        system(action)
      else
        action.call
      end
    end
  end
  
end