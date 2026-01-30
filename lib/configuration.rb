require 'json'
require_relative './errors'

module SlackMeet
  # Configuration loader for meeting settings.
  # Loads configuration from config.json with environment variable overrides.
  #
  # @example
  #   config = Configuration.load
  #   config.access_type # => "TRUSTED"
  #   config.auto_transcribe # => false
  #
  class Configuration
    # Valid access type values
    VALID_ACCESS_TYPES = %w[OPEN TRUSTED RESTRICTED].freeze

    # Valid moderation values
    VALID_MODERATION_VALUES = %w[OFF ON].freeze

    attr_reader :access_type, :auto_transcribe, :auto_record, :smart_notes, :moderation

    # Loads configuration from config.json with environment variable overrides.
    #
    # @return [Configuration] The loaded configuration
    # @raise [ConfigurationError] If configuration is invalid
    def self.load
      config_data = load_config_file
      new(config_data)
    end

    # Initialize a new configuration instance.
    #
    # @param config_data [Hash] Configuration data
    # @raise [ConfigurationError] If configuration is invalid
    def initialize(config_data = {})
      @access_type = parse_access_type(config_data)
      @auto_transcribe = parse_boolean(config_data, 'auto_transcribe', false)
      @auto_record = parse_boolean(config_data, 'auto_record', false)
      @smart_notes = parse_boolean(config_data, 'smart_notes', false)
      @moderation = parse_moderation(config_data)

      validate!
    end

    private

    # Load configuration from config.json file
    def self.load_config_file
      # Get the project root (parent of lib/)
      project_root = File.expand_path('..', __dir__)
      config_path = File.join(project_root, 'config.json')

      unless File.exist?(config_path)
        raise Errors::ConfigurationError, "Configuration file not found: #{config_path}\n" \
                                          "Please create config.json with meeting settings."
      end

      JSON.parse(File.read(config_path))
    rescue JSON::ParserError => e
      raise Errors::ConfigurationError, "Invalid JSON in config.json: #{e.message}"
    end

    def parse_access_type(config_data)
      value = ENV['MEET_ACCESS_TYPE'] || config_data['access_type'] || 'TRUSTED'
      value.upcase
    end

    def parse_boolean(config_data, key, default)
      env_key = "MEET_#{key.upcase}"
      value = ENV[env_key] || config_data[key]

      return default if value.nil?

      case value
      when true, 'true', '1', 'yes', 'on'
        true
      when false, 'false', '0', 'no', 'off'
        false
      else
        default
      end
    end

    def parse_moderation(config_data)
      value = ENV['MEET_MODERATION'] || config_data['moderation'] || 'OFF'
      value.upcase
    end

    def validate!
      unless VALID_ACCESS_TYPES.include?(@access_type)
        raise Errors::ConfigurationError, "Invalid access_type: #{@access_type}. " \
                                          "Must be one of: #{VALID_ACCESS_TYPES.join(', ')}"
      end

      unless VALID_MODERATION_VALUES.include?(@moderation)
        raise Errors::ConfigurationError, "Invalid moderation: #{@moderation}. " \
                                          "Must be one of: #{VALID_MODERATION_VALUES.join(', ')}"
      end
    end
  end
end
