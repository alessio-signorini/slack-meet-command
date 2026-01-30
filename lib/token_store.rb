require_relative '../app/models/user_token'
require_relative './errors'

module SlackMeet
  # Manages storage and retrieval of user OAuth tokens.
  #
  # @example
  #   store = TokenStore.new
  #   store.store_tokens(
  #     slack_user_id: "U123",
  #     slack_team_id: "T123",
  #     access_token: "ya29.abc",
  #     refresh_token: "1//xyz",
  #     expires_at: Time.now + 3600
  #   )
  #
  class TokenStore
    # Find token by Slack user ID
    #
    # @param slack_user_id [String] Slack user ID
    # @return [UserToken, nil] The token record or nil if not found
    def find_by_slack_user(slack_user_id)
      UserToken.where(slack_user_id: slack_user_id).first
    end

    # Store new tokens or update existing ones
    #
    # @param slack_user_id [String] Slack user ID
    # @param slack_team_id [String] Slack team ID
    # @param access_token [String] Google access token
    # @param refresh_token [String, nil] Google refresh token
    # @param expires_at [Time] Token expiry time
    # @return [UserToken] The stored token record
    def store_tokens(slack_user_id:, slack_team_id:, access_token:, refresh_token:, expires_at:)
      existing = find_by_slack_user(slack_user_id)

      if existing
        existing.update(
          slack_team_id: slack_team_id,
          google_access_token: access_token,
          google_refresh_token: refresh_token || existing.google_refresh_token,
          google_token_expiry: expires_at,
          updated_at: Time.now
        )
        existing
      else
        UserToken.create(
          slack_user_id: slack_user_id,
          slack_team_id: slack_team_id,
          google_access_token: access_token,
          google_refresh_token: refresh_token,
          google_token_expiry: expires_at
        )
      end
    end

    # Update only the access token (used during refresh)
    #
    # @param slack_user_id [String] Slack user ID
    # @param access_token [String] New access token
    # @param expires_at [Time] New expiry time
    # @return [UserToken, nil] The updated token record or nil if not found
    def update_access_token(slack_user_id:, access_token:, expires_at:)
      token = find_by_slack_user(slack_user_id)
      return nil unless token

      token.update(
        google_access_token: access_token,
        google_token_expiry: expires_at,
        updated_at: Time.now
      )
      token
    end

    # Delete tokens for a user
    #
    # @param slack_user_id [String] Slack user ID
    # @return [Integer] Number of records deleted
    def delete_for_user(slack_user_id)
      UserToken.where(slack_user_id: slack_user_id).delete
    end

    # Check if token is expiring soon (within 5 minutes)
    #
    # @param slack_user_id [String] Slack user ID
    # @return [Boolean] True if token expires within 5 minutes
    def token_expiring_soon?(slack_user_id)
      token = find_by_slack_user(slack_user_id)
      return false unless token
      return false unless token.google_token_expiry

      # Check if expiring within 5 minutes
      token.google_token_expiry < (Time.now + (5 * 60))
    end
  end
end
