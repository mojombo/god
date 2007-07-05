module God
  
  class Meddle < Base
    # config
    attr_accessor :interval

    # drb
    attr_accessor :server
    
    # api
    attr_accessor :watches, :timer
    
    # Create a new instance that is ready for use by a configuration file
    def initialize(options = {})
      self.watches = []
      self.server  = Server.new(self, options[:host], options[:port])
      self.timer = Timer.new
    end
      
    # Instantiate a new, empty Watch object and pass it to the mandatory
    # block. The attributes of the watch will be set by the configuration
    # file.
    def watch
      w = Watch.new(self)
      yield(w)
      @watches << w
    end
    
    def monitor
      
    end
    
    # def monitor
    #   threads = []
    #   
    #   @watches.each do |w|
    #     threads << Thread.new do
    #       while true do
    #         w.run
    #         sleep self.interval
    #       end
    #     end
    #   end
    #   
    #   threads.each { |t| t.join }
    # end
  end
  
end
