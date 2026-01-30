require_relative '../../lib/google_meet_client'
require_relative '../../lib/configuration'

module SlackMeet
  # Service for creating Google Meet meetings.
  #
  # @example
  #   creator = MeetingCreator.new(
  #     google_meet_client: GoogleMeetClient.new,
  #     configuration: Configuration.load
  #   )
  #   result = creator.create(access_token: token, meeting_name: 'Standup')
  #
  class MeetingCreator
    # @param google_meet_client [GoogleMeetClient] Google Meet API client
    # @param configuration [Configuration] Meeting configuration
    def initialize(google_meet_client:, configuration:)
      @google_meet_client = google_meet_client
      @configuration = configuration
    end

    # Create a new meeting
    #
    # @param access_token [String] Google access token
    # @param meeting_name [String, nil] Optional meeting name
    # @return [Hash] Meeting details with :meeting_uri, :meeting_code, :meeting_name
    # @raise [GoogleApiError] If API call fails
    def create(access_token:, meeting_name: nil)
      meeting_name = sanitize_meeting_name(meeting_name)
      
      config = build_config
      
      result = @google_meet_client.create_space(
        access_token: access_token,
        config: config
      )
      
      result.merge(meeting_name: meeting_name)
    end

    private

    def sanitize_meeting_name(name)
      return 'New Meeting' if name.nil? || name.strip.empty?
      name.strip
    end

    def build_config
      {
        access_type: @configuration.access_type,
        moderation: @configuration.moderation,
        auto_transcribe: @configuration.auto_transcribe,
        auto_record: @configuration.auto_record,
        smart_notes: @configuration.smart_notes
      }
    end
  end
end
