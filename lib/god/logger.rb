module God
  
  class Logger < ::Logger
    SYSLOG_EQUIVALENTS = {:fatal => :crit,
                          :error => :err,
                          :warn => :debug,
                          :info => :debug,
                          :debug => :debug}
    
    attr_accessor :logs
    
    class << self
      attr_accessor :syslog
    end
    
    self.syslog ||= true
    
    # Instantiate a new Logger object
    def initialize
      super($stdout)
      self.logs = {}
      @mutex = Mutex.new
      @capture = nil
      @templogio = StringIO.new
      @templog = ::Logger.new(@templogio)
      @templog.level = Logger::INFO
      load_syslog
    end
    
    # If Logger.syslog is true then attempt to load the syslog bindings. If syslog
    # cannot be loaded, then set Logger.syslog to false and continue.
    #
    # Returns nothing
    def load_syslog
      return unless Logger.syslog
      
      begin
        require 'syslog'
        
        # Ensure that Syslog is open
        begin
          Syslog.open('god')
        rescue RuntimeError
          Syslog.reopen('god')
        end
      rescue Exception
        Logger.syslog = false
      end
    end
    
    # Log a message
    #   +watch+ is the String name of the Watch (may be nil if not Watch is applicable)
    #   +level+ is the log level [:debug|:info|:warn|:error|:fatal]
    #   +text+ is the String message
    #
    # Returns nothing
    def log(watch, level, text)
      # initialize watch log if necessary
      self.logs[watch.name] ||= Timeline.new(God::LOG_BUFFER_SIZE_DEFAULT) if watch
      
      # push onto capture and timeline for the given watch
      @templogio.truncate(0)
      @templogio.rewind
      @templog.send(level, text % [])
      @mutex.synchronize do
        @capture.puts(@templogio.string) if @capture
        self.logs[watch.name] << [Time.now, @templogio.string] if watch
      end
      
      # send to regular logger
      self.send(level, text % [])
      
      # send to syslog
      Syslog.send(SYSLOG_EQUIVALENTS[level], text) if Logger.syslog
    end
    
    # Get all log output for a given Watch since a certain Time.
    #   +watch_name+ is the String name of the Watch
    #   +since+ is the Time since which to fetch log lines
    #
    # Returns String
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
    
    # private
    
    # Enable capturing of log
    #
    # Returns nothing
    def start_capture
      @mutex.synchronize do
        @capture = StringIO.new
      end
    end
    
    # Disable capturing of log and return what was captured since
    # capturing was enabled with Logger#start_capture
    #
    # Returns String
    def finish_capture
      @mutex.synchronize do
        cap = @capture.string
        @capture = nil
        cap
      end
    end
  end
  
end