module God

  class SimpleLogger
    DEBUG = 2
    INFO = 4
    WARN = 8
    ERROR = 16
    FATAL = 32

    SEV_LABEL = {DEBUG => 'DEBUG',
                 INFO => 'INFO',
                 WARN => 'WARN',
                 ERROR => 'ERROR',
                 FATAL => 'FATAL'}

    CONSTANT_TO_SYMBOL = { DEBUG => :debug,
                           INFO => :info,
                           WARN => :warn,
                           ERROR => :error,
                           FATAL => :fatal }

    attr_accessor :datetime_format, :level

    def initialize(io)
      @io = io
      @level = INFO
      @datetime_format = "%Y-%m-%d %H:%M:%S"
    end

    def output(level, msg)
      return if level < self.level

      time = Time.now.strftime(self.datetime_format)
      label = SEV_LABEL[level]
      @io.print("#{label[0..0]} [#{time}] #{label.rjust(5)}: #{msg}\n")
    end

    def fatal(msg)
      self.output(FATAL, msg)
    end

    def error(msg)
      self.output(ERROR, msg)
    end

    def warn(msg)
      self.output(WARN, msg)
    end

    def info(msg)
      self.output(INFO, msg)
    end

    def debug(msg)
      self.output(DEBUG, msg)
    end
  end

end
