require 'httparty'
require 'json'
require 'digest'

module SlackMeet
  # Client for sending events to Google Analytics 4 Measurement Protocol.
  # Sends minimal, privacy-focused event data with anonymous user tracking.
  #
  # Uses MD5(user_id:team_id) as client_id to track usage patterns without
  # exposing actual user identities. Same user always gets same hash.
  #
  # @example
  #   client = GoogleAnalyticsClient.new(measurement_id: 'G-XXXXXXXXXX', api_secret: 'secret')
  #   client.track_meet_command_used(has_title: true, user_id: 'U123', team_id: 'T456')
  #
  class GoogleAnalyticsClient
    GA4_ENDPOINT = 'https://www.google-analytics.com/mp/collect'

    # @param measurement_id [String] GA4 Measurement ID (G-XXXXXXXXXX)
    # @param api_secret [String] GA4 API secret
    # @param logger [Logger] Logger instance
    def initialize(measurement_id:, api_secret:, logger: nil)
      @measurement_id = measurement_id
      @api_secret = api_secret
      @logger = logger
      @enabled = !measurement_id.nil? && !measurement_id.empty? && !api_secret.nil? && !api_secret.empty?
    end

    # Track when a /meet command is used
    #
    # @param has_title [Boolean] Whether user provided a meeting title
    # @param user_id [String] Slack user ID (will be hashed)
    # @param team_id [String] Slack team ID (will be hashed)
    def track_meet_command_used(has_title:, user_id:, team_id:)
      return unless @enabled

      params = {
        event_name: 'meet_command_used',
        event_params: {
          has_custom_title: has_title
        }
      }

      send_event(params, user_id: user_id, team_id: team_id)
    end

    # Track when a user completes OAuth authentication
    #
    # @param user_id [String] Slack user ID (will be hashed)
    # @param team_id [String] Slack team ID (will be hashed)
    def track_auth_completed(user_id:, team_id:)
      return unless @enabled

      params = {
        event_name: 'oauth_completed',
        event_params: {
          auth_provider: 'google'
        }
      }

      send_event(params, user_id: user_id, team_id: team_id)
    end

    private

    def send_event(event_data, user_id:, team_id:)
      # Use MD5 hash of user_id+team_id for consistent but anonymous tracking
      # This allows tracking usage patterns without exposing actual user identities
      client_id = Digest::MD5.hexdigest("#{user_id}:#{team_id}")

      payload = {
        client_id: client_id,
        events: [event_data]
      }

      url = "#{GA4_ENDPOINT}?measurement_id=#{@measurement_id}&api_secret=#{@api_secret}"

      response = HTTParty.post(
        url,
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 5
      )

      if response.success?
        @logger&.debug(message: 'GA4 event sent', event: event_data[:event_name])
      else
        @logger&.warn(message: 'GA4 event failed', status: response.code, event: event_data[:event_name])
      end
    rescue StandardError => e
      @logger&.error(message: 'GA4 tracking error', error: e.message)
    end
  end
end
