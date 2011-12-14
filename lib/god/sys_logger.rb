begin
  require 'syslog'

  module God

    class SysLogger
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
        Syslog.mask = Syslog::LOG_UPTO(SYMBOL_EQUIVALENTS[level])
      end

      # Log a message to syslog.
      #   +level+ is the Symbol level of the message. One of:
      #           [:fatal | :error | :warn | :info | :debug ]
      #   +text+ is the String text of the message
      #
      # Returns Nothing
      def self.log(level, text)
        unless Syslog.opened?
          facility = Syslog::LOG_USER
          facility = God::Logger.syslog_facility if God::Logger.syslog_facility

          # Ensure that Syslog is open
          begin
            Syslog.open('god', Syslog::LOG_PID | Syslog::LOG_CONS, facility)
          rescue RuntimeError
            Syslog.reopen('god', Syslog::LOG_PID | Syslog::LOG_CONS, facility)
          end
        end

        Syslog.log(SYMBOL_EQUIVALENTS[level], '%s', text)
      end
    end

  end
rescue Object => e
  puts "Syslog could not be enabled: #{e.message}"
end
