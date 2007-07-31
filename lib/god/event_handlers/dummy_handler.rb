module God
  class DummyHandler
    def self.register_process
      raise NotImplementedError
    end
    
    def self.handle_events
      raise NotImplementedError
    end
  end
end