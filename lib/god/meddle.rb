module God
  
  class Meddle < Base
    # config
    attr_accessor :interval
    
    # api
    attr_accessor :watches
    
    # Create a new instance that is ready for use by a configuration file
    def initialize
      self.watches = []
    end
      
    # Instantiate a new, empty Watch object and pass it to the mandatory
    # block. The attributes of the watch must be set by the configuration
    # file.
    def watch
      w = Watch.new
      yield(w)
      @watches << w
    end
    
    def monitor
      threads = []
      
      @watches.each do |w|
        threads << Thread.new do
          while true do
            w.run
            sleep self.interval
          end
        end
      end
      
      threads.each { |t| t.join }
    end
  end
  
end