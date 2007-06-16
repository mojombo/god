module God
  
  class Watch < Base
    # config
    attr_accessor :name, :cwd, :start, :stop, :grace
    
    # api
    attr_accessor :conditions
    
    # 
    def initialize
      # no grace period by default
      self.grace = 0
      
      # keep track of which action each condition belongs to
      @action = nil
      
      # the list of conditions for each action
      self.conditions = {:start => []}
    end
    
    def start_if
      @action = :start
      yield(self)
      @action = nil
    end
    
    # Instantiate a Condition of type +kind+ and pass it into the mandatory
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
      
      yield(c)
      
      # exit if the Condition is invalid, the Condition will have printed
      # out its own error messages by now
      unless c.valid?
        exit
      end
      
      self.conditions[@action] << c
    end
    
    def run
      self.conditions[:start].each do |c|
        if c.test
          puts self.name + ' ' + c.class.name + ' [ok]'
        else
          puts self.name + ' ' + c.class.name + ' [fail]'
          c.after
          return :start
        end
      end
      
      nil
    end
    
    def action(a)
      case a
      when :start
        puts self.start
        Dir.chdir(self.cwd) do
          system(self.start)
        end
        sleep(self.grace)
      end
    end
  end
  
end