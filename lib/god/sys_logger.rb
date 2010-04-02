require 'syslog'

# Ensure that Syslog is open
begin
  Syslog.open('god')
rescue RuntimeError
  Syslog.reopen('god')
end

module God

  class SysLogger
    CONSTANT_EQUIVALENTS = { SimpleLogger::FATAL => Syslog::LOG_CRIT,
                             SimpleLogger::ERROR => Syslog::LOG_ERR,
                             SimpleLogger::WARN => Syslog::LOG_WARNING,
                             SimpleLogger::INFO => Syslog::LOG_INFO,
                             SimpleLogger::DEBUG => Syslog::LOG_DEBUG }

    SYMBOL_EQUIVALENTS = { :fatal => Syslog::LOG_CRIT,
                           :error => Syslog::LOG_ERR,
                           :warn => Syslog::LOG_WARNING,
                           :info => Syslog::LOG_INFO,
                           :debug => Syslog::LOG_DEBUG }

    # Set the log level
    #   +level+ is the Symbol level to set as maximum. One of:
    #           [:fatal | :error | :warn | :info | :debug ]
    #
    # Returns Nothing
    def self.level=(level)
      Syslog.mask = Syslog::LOG_UPTO(CONSTANT_EQUIVALENTS[level])
    end

    # Log a message to syslog.
    #   +level+ is the Symbol level of the message. One of:
    #           [:fatal | :error | :warn | :info | :debug ]
    #   +text+ is the String text of the message
    #
    # Returns Nothing
    def self.log(level, text)
      Syslog.log(SYMBOL_EQUIVALENTS[level], text)
    end
  end

end