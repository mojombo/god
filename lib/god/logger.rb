module God

  class Logger < SimpleLogger

    attr_accessor :logs

    class << self
      attr_accessor :syslog
    end

    self.syslog = defined?(Syslog)

    # Instantiate a new Logger object
    def initialize(io = $stdout)
      super(io)
      self.logs = {}
      @mutex = Mutex.new
      @capture = nil
      @spool = Time.now - 10
      @templogio = StringIO.new
      @templog = SimpleLogger.new(@templogio)
      @templog.level = Logger::INFO
    end


    def level=(lev)
      SysLogger.level = SimpleLogger::CONSTANT_TO_SYMBOL[lev] if Logger.syslog
      super(lev)
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
      if @capture || (watch && (Time.now - @spool < 2))
        @mutex.synchronize do
          @templogio.truncate(0)
          @templogio.rewind
          @templog.send(level, text)

          message = @templogio.string.dup

          if @capture
            @capture.puts(message)
          else
            self.logs[watch.name] << [Time.now, message]
          end
        end
      end

      # send to regular logger
      self.send(level, text)

      # send to syslog
      SysLogger.log(level, text) if Logger.syslog
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
        @spool = Time.now
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
        cap = @capture.string if @capture
        @capture = nil
        cap
      end
    end
  end

end
