module God
  def self.registry
    @registry ||= Registry.new
  end

  class Registry
    def initialize
      @storage = {}
    end

    def add(item)
      # raise TypeError unless item.is_a? God::Process
      @storage[item.name] = item
    end

    def remove(item)
      @storage.delete(item.name)
    end

    def size
      @storage.size
    end

    def [](name)
      @storage[name]
    end

    def reset
      @storage.clear
    end
  end
end
