module God
  class DummyHandler
    EVENT_SYSTEM = "none"
    
    def self.register_process
      raise NotImplementedError
    end
    
    def self.handle_events
      raise NotImplementedError
    end
  end
end