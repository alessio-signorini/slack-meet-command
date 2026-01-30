require 'net/http'
require 'json'
require 'uri'
require_relative './errors'

module SlackMeet
  # Client for Google Meet API operations.
  #
  # @example
  #   client = GoogleMeetClient.new
  #   result = client.create_space(
  #     access_token: 'ya29.abc...',
  #     config: { access_type: 'TRUSTED', auto_transcribe: false }
  #   )
  #   result[:meeting_uri] # => "https://meet.google.com/abc-defg-hij"
  #
  class GoogleMeetClient
    API_ENDPOINT = 'https://meet.googleapis.com/v2/spaces'.freeze

    # Create a new Google Meet space
    #
    # @param access_token [String] Google access token
    # @param config [Hash] Meeting configuration
    # @option config [String] :access_type Access type (OPEN, TRUSTED, RESTRICTED)
    # @option config [Boolean] :auto_transcribe Enable auto-transcription
    # @option config [Boolean] :auto_record Enable auto-recording
    # @option config [Boolean] :smart_notes Enable smart notes
    # @option config [String] :moderation Moderation mode (OFF, ON)
    # @return [Hash] Meeting details with :meeting_uri, :meeting_code, :space_name
    # @raise [GoogleApiError] If API call fails
    def create_space(access_token:, config: {})
      uri = URI.parse(API_ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path, {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}"
      })

      request.body = JSON.generate(build_space_config(config))

      response = http.request(request)

      unless response.code.to_i == 200
        error_message = "Failed to create meeting: #{response.code}"
        begin
          error_data = JSON.parse(response.body)
          error_message = "#{error_message} - #{error_data['error']['message']}" if error_data['error']
        rescue JSON::ParserError
          # Use default message
        end
        
        raise Errors::GoogleApiError.new(error_message, status_code: response.code.to_i)
      end

      data = JSON.parse(response.body)
      
      {
        meeting_uri: data['meetingUri'],
        meeting_code: data['meetingCode'],
        space_name: data['name']
      }
    rescue JSON::ParserError
      raise Errors::GoogleApiError.new('Invalid response from Google Meet API', status_code: response.code.to_i)
    end

    private

    def build_space_config(config)
      space_config = {}
      
      # Build config object
      config_obj = {}
      config_obj[:accessType] = config[:access_type] if config[:access_type]
      config_obj[:moderation] = config[:moderation] if config[:moderation]
      space_config[:config] = config_obj unless config_obj.empty?

      # Build artifact config
      artifact_config = {}
      
      if config[:auto_transcribe]
        artifact_config[:transcriptionConfig] = {
          autoTranscriptionGeneration: config[:auto_transcribe] ? 'ON' : 'OFF'
        }
      end
      
      if config[:auto_record]
        artifact_config[:recordingConfig] = {
          autoRecordingGeneration: config[:auto_record] ? 'ON' : 'OFF'
        }
      end
      
      if config[:smart_notes]
        artifact_config[:smartNotesConfig] = {
          autoSmartNotesGeneration: config[:smart_notes] ? 'ON' : 'OFF'
        }
      end

      space_config[:artifactConfig] = artifact_config unless artifact_config.empty?

      space_config
    end
  end
end
