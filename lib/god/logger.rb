module God
  
  class Logger < ::Logger
    attr_accessor :logs
    
    def initialize
      super(STDOUT)
      self.logs = {}
      @mutex = Mutex.new
    end
    
    def log(watch, level, text)
      # initialize watch log if necessary
      self.logs[watch.name] ||= Timeline.new(God::LOG_BUFFER_SIZE_DEFAULT)
      
      # push onto timeline for the given watch
      buf = StringIO.new
      templog = ::Logger.new(buf)
      templog.send(level, text)
      @mutex.synchronize do
        self.logs[watch.name] << [Time.now, buf.string]
      end
      templog.close
      
      # send to regular logger
      self.send(level, text)
    end
    
    def watch_log_since(watch_name, since)
      # initialize watch log if necessary
      self.logs[watch_name] ||= Timeline.new(God::LOG_BUFFER_SIZE_DEFAULT)
      
      # get and join lines since given time
      @mutex.synchronize do
        self.logs[watch_name].select do |x|
          x.first > since
        end.map do |x|
          x[1]
        end.join
      end
    end
  end
  
end