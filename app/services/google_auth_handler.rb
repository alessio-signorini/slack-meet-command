require_relative '../../lib/google_auth_client'
require_relative '../../lib/token_store'

module SlackMeet
  # Handles Google OAuth flow.
  #
  # @example
  #   handler = GoogleAuthHandler.new(
  #     google_auth_client: GoogleAuthClient.new(...),
  #     token_store: TokenStore.new,
  #     configuration: Configuration.load
  #   )
  #   url = handler.authorization_url(slack_user_id: 'U123', slack_team_id: 'T123')
  #
  class GoogleAuthHandler
    # @param google_auth_client [GoogleAuthClient] Google OAuth client
    # @param token_store [TokenStore] Token storage
    # @param configuration [Configuration] App configuration
    def initialize(google_auth_client:, token_store:, configuration:)
      @google_auth_client = google_auth_client
      @token_store = token_store
      @configuration = configuration
    end

    # Generate authorization URL
    #
    # @param slack_user_id [String] Slack user ID
    # @param slack_team_id [String] Slack team ID
    # @param redirect_uri [String] OAuth redirect URI
    # @return [String] Authorization URL
    def authorization_url(slack_user_id:, slack_team_id:, redirect_uri:)
      state = encode_state(slack_user_id: slack_user_id, slack_team_id: slack_team_id)
      @google_auth_client.authorization_url(state: state, redirect_uri: redirect_uri)
    end

    # Handle OAuth callback
    #
    # @param code [String] Authorization code
    # @param state [String] State parameter
    # @param redirect_uri [String] OAuth redirect URI
    # @return [Hash] State data with :slack_user_id, :slack_team_id
    # @raise [GoogleApiError] If code exchange fails
    def handle_callback(code:, state:, redirect_uri:)
      state_data = decode_state(state)
      
      result = @google_auth_client.exchange_code(
        code: code,
        redirect_uri: redirect_uri
      )
      
      expires_at = Time.now + result[:expires_in]
      
      @token_store.store_tokens(
        slack_user_id: state_data[:slack_user_id],
        slack_team_id: state_data[:slack_team_id],
        access_token: result[:access_token],
        refresh_token: result[:refresh_token],
        expires_at: expires_at
      )
      
      state_data
    end

    private

    def encode_state(slack_user_id:, slack_team_id:)
      data = {
        slack_user_id: slack_user_id,
        slack_team_id: slack_team_id
      }
      Base64.urlsafe_encode64(JSON.generate(data))
    end

    def decode_state(state)
      data = JSON.parse(Base64.urlsafe_decode64(state))
      {
        slack_user_id: data['slack_user_id'],
        slack_team_id: data['slack_team_id']
      }
    rescue JSON::ParserError, ArgumentError
      raise Errors::ConfigurationError, 'Invalid state parameter'
    end
  end
end
