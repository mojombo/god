module God
  
  class Meddle < Base
    # drb
    attr_accessor :server
    
    # api
    attr_accessor :watches, :groups
    
    # Create a new instance that is ready for use by a configuration file
    def initialize(options = {})
      self.watches = {}
      self.groups = {}
      self.server  = Server.new(self, options[:host], options[:port])
    end
      
    # Instantiate a new, empty Watch object and pass it to the mandatory
    # block. The attributes of the watch will be set by the configuration
    # file.
    def watch
      w = Watch.new(self)
      yield(w)
      
      # ensure the new watch has a unique name
      if @watches[w.name] || @groups[w.name]
        abort "Watch name '#{w.name}' already used for a Watch or Group"
      end
      
      # add to list of watches
      @watches[w.name] = w
      
      # add to group if specified
      if w.group
        # ensure group name hasn't been used for a watch already
        if @watches[w.group]
          abort "Group name '#{w.group}' already used for a Watch"
        end
      
        @groups[w.group] ||= []
        @groups[w.group] << w.name
      end
    end
    
    # Start monitoring any watches set to autostart
    def monitor
      @watches.values.each { |w| w.monitor if w.autostart? }
    end
  end
  
end
