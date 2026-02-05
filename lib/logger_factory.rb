require 'logger'
require 'json'

module SlackMeet
  # Factory for creating environment-aware loggers.
  # 
  # In development, logs are human-readable.
  # In production, logs are JSON formatted.
  #
  # @example
  #   logger = LoggerFactory.create
  #   logger.info("Meeting created", meeting_code: "abc-defg-hij", user_id: "U123")
  #
  class LoggerFactory
    # Creates a configured logger instance.
    #
    # @param output [IO] Output stream (default: STDOUT)
    # @return [Logger] Configured logger
    def self.create(output: $stdout)
      logger = Logger.new(output)
      logger.level = log_level
      logger.formatter = formatter
      logger
    end

    # Determine log level based on LOG_LEVEL env variable or RACK_ENV
    # LOG_LEVEL can be: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
    def self.log_level
      if ENV['LOG_LEVEL']
        begin
          Logger.const_get(ENV['LOG_LEVEL'].upcase)
        rescue NameError
          Logger::INFO # fallback to INFO if invalid level specified
        end
      else
        case ENV['RACK_ENV']
        when 'production'
          Logger::INFO
        else
          Logger::DEBUG
        end
      end
    end

    # Get the appropriate formatter based on environment
    def self.formatter
      case ENV['RACK_ENV']
      when 'production'
        production_formatter
      else
        development_formatter
      end
    end

    # Human-readable formatter for development
    def self.development_formatter
      proc do |severity, datetime, _progname, msg|
        formatted_msg = format_message(msg)
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.ljust(5)} #{formatted_msg}\n"
      end
    end

    # JSON formatter for production
    def self.production_formatter
      proc do |severity, datetime, _progname, msg|
        log_entry = {
          timestamp: datetime.utc.iso8601,
          level: severity,
        }

        if msg.is_a?(Hash)
          log_entry.merge!(msg)
        else
          log_entry[:message] = msg.to_s
        end

        "#{JSON.generate(log_entry)}\n"
      end
    end

    # Format message based on type
    def self.format_message(msg)
      if msg.is_a?(Hash)
        message = msg.delete(:message) || msg.delete('message')
        context = msg.map { |k, v| "#{k}=#{v}" }.join(' ')
        [message, context].compact.join(' | ')
      else
        msg.to_s
      end
    end
  end
end
