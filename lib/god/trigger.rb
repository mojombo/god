module God

  class Trigger

    class << self
      attr_accessor :triggers # {task.name => condition}
    end

    # init
    self.triggers = {}
    @mutex = Mutex.new

    def self.register(condition)
      @mutex.synchronize do
        self.triggers[condition.watch.name] ||= []
        self.triggers[condition.watch.name] << condition
      end
    end

    def self.deregister(condition)
      @mutex.synchronize do
        self.triggers[condition.watch.name].delete(condition)
        self.triggers.delete(condition.watch.name) if self.triggers[condition.watch.name].empty?
      end
    end

    def self.broadcast(task, message, payload)
      return unless self.triggers[task.name]

      @mutex.synchronize do
        self.triggers[task.name].each do |t|
          t.process(message, payload)
        end
      end
    end

    def self.reset
      self.triggers.clear
    end

  end

end
