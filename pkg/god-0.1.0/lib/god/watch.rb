module God
  
  class Watch
    attr_accessor :name, :cwd, :start, :stop
    
    def initialize
      @action = nil
      @conditions = {:start => []}
    end
    
    def start_if
      @action = :start
      yield(self)
    end
    
    def condition(kind)
      begin
        c = Condition.generate(kind)
      rescue
        puts "No condition found for #{kind}"
        exit
      end
      
      yield(c)
      
      unless c.valid?
        exit
      end
      
      @conditions[@action] << c
    end
    
    def run
      @conditions[:start].each do |c|
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
      end
    end
  end
  
end