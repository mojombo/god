module God
  
  class Meddle < Base
    # drb
    attr_accessor :server
    
    # api
    attr_accessor :watches
    
    # Create a new instance that is ready for use by a configuration file
    def initialize(options = {})
      self.watches = {}
      self.server  = Server.new(self, options[:host], options[:port])
    end
      
    # Instantiate a new, empty Watch object and pass it to the mandatory
    # block. The attributes of the watch will be set by the configuration
    # file.
    def watch
      w = Watch.new(self)
      yield(w)
      
      # ensure the new watch has a unique name
      if @watches[w.name]
        abort "Duplicate Watch with name '#{w.name}'"
      end
      
      # add to list of watches
      @watches[w.name] = w
    end
    
    # Start monitoring any watches set to autostart
    def monitor
      @watches.values.each { |w| w.monitor if w.autostart? }
    end
  end
  
end
