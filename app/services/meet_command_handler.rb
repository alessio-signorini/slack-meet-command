require_relative '../../lib/token_store'
require_relative '../../lib/google_auth_client'
require_relative '../../lib/slack_responder'
require_relative '../services/meeting_creator'
require_relative '../../lib/async_job_runner'
require_relative '../../lib/logger_factory'

module SlackMeet
  # Handles the /meet command flow.
  #
  # @example
  #   handler = MeetCommandHandler.new(
  #     token_store: TokenStore.new,
  #     meeting_creator: MeetingCreator.new(...),
  #     slack_responder: SlackResponder.new(...),
  #     google_auth_client: GoogleAuthClient.new(...),
  #     async_job_runner: AsyncJobRunner,
  #     logger: logger
  #   )
  #   handler.call(params)
  #
  class MeetCommandHandler
    # @param token_store [TokenStore] Token storage
    # @param meeting_creator [MeetingCreator] Meeting creator service
    # @param slack_responder [SlackResponder] Slack message formatter
    # @param google_auth_client [GoogleAuthClient] Google OAuth client
    # @param async_job_runner [Class] Async job runner class
    # @param logger [Logger] Logger instance
    # @param ga_client [GoogleAnalyticsClient, nil] Optional Google Analytics client
    def initialize(token_store:, meeting_creator:, slack_responder:, google_auth_client:, async_job_runner:, logger:, ga_client: nil)
      @token_store = token_store
      @meeting_creator = meeting_creator
      @slack_responder = slack_responder
      @google_auth_client = google_auth_client
      @async_job_runner = async_job_runner
      @logger = logger
      @ga_client = ga_client
    end

    # Handle /meet command
    #
    # @param params [Hash] Request parameters from Slack
    # @param base_url [String] Base URL of the application (inferred from request)
    # @return [Hash] Immediate acknowledgment message
    def call(params, base_url:)
      slack_user_id = params['user_id']
      slack_team_id = params['team_id']
      response_url = params['response_url']
      meeting_name = params['text']
      
      # Check for existing token
      token = @token_store.find_by_slack_user(slack_user_id)
      
      unless token
        return handle_auth_required(slack_user_id, slack_team_id, response_url, base_url)
      end
      
      # Spawn async job to create meeting
      @async_job_runner.perform_async(logger: @logger) do
        process_meeting_creation(token, meeting_name, response_url, base_url)
      end
      
      @slack_responder.immediate_acknowledgment
    end

    private

    # Handle authentication requirement - used for both initial auth and re-auth
    #
    # @param slack_user_id [String] Slack user ID
    # @param slack_team_id [String] Slack team ID
    # @param response_url [String] Slack response URL
    # @param base_url [String] Base URL of the application
    # @return [Hash] Auth required message
    def handle_auth_required(slack_user_id, slack_team_id, response_url, base_url)
      # Store response_url for later use after OAuth
      @token_store.store_pending_response_url(
        slack_user_id: slack_user_id,
        slack_team_id: slack_team_id,
        response_url: response_url
      )
      
      auth_url = build_auth_url(slack_user_id, slack_team_id, base_url)
      @slack_responder.auth_required_message(auth_url: auth_url)
    end

    def build_auth_url(slack_user_id, slack_team_id, base_url)
      state = Base64.urlsafe_encode64(JSON.generate({
        slack_user_id: slack_user_id,
        slack_team_id: slack_team_id
      }))
      
      "#{base_url}/auth/google?state=#{state}"
    end

    def process_meeting_creation(token, meeting_name, response_url, base_url)
      # Refresh token if needed
      access_token = @token_store.refresh_if_needed(
        token.slack_user_id,
        google_auth_client: @google_auth_client
      )
      
      # Create meeting
      result = @meeting_creator.create(
        access_token: access_token,
        meeting_name: meeting_name
      )
      
      # Clear any pending response_url (from auth flow)
      @token_store.get_and_clear_pending_response_url(token.slack_user_id)
      
      # Post the meeting link to the channel
      message = @slack_responder.meeting_created_message(
        meeting_name: result[:meeting_name],
        meeting_uri: result[:meeting_uri]
      )
      
      @slack_responder.post_to_response_url(
        response_url: response_url,
        payload: message
      )
      
      # Track /meet command usage (only track if title was provided, not the title itself)
      @ga_client&.track_meet_command_used(
        has_title: !meeting_name.nil? && !meeting_name.strip.empty?,
        user_id: token.slack_user_id,
        team_id: token.slack_team_id
      )
      
      @logger.info(message: 'Meeting created', meeting_code: result[:meeting_code], user_id: token.slack_user_id)
    rescue Errors::TokenRefreshError => e
      @logger.warn(message: 'Token refresh failed', user_id: token.slack_user_id, error: e.message)
      
      # Delete invalid tokens
      @token_store.delete_for_user(token.slack_user_id)
      
      # Use the same auth handling as initial auth
      message = handle_auth_required(token.slack_user_id, token.slack_team_id, response_url, base_url)
      
      @slack_responder.post_to_response_url(
        response_url: response_url,
        payload: message
      )
    rescue Errors::GoogleApiError => e
      @logger.error(message: 'Google API error', error: e.message, status_code: e.status_code)
      
      # Check if this is an authentication error (401)
      if e.status_code == 401
        @logger.warn(message: 'Token invalid or revoked', user_id: token.slack_user_id)
        
        # Delete invalid tokens
        @token_store.delete_for_user(token.slack_user_id)
        
        # Use the same auth handling as initial auth
        message = handle_auth_required(token.slack_user_id, token.slack_team_id, response_url, base_url)
      else
        message = @slack_responder.error_message(
          text: '❌ Failed to create meeting. Please try again.'
        )
      end
      
      @slack_responder.post_to_response_url(
        response_url: response_url,
        payload: message
      )
    rescue StandardError => e
      @logger.error(message: 'Unexpected error', error: e.message, backtrace: e.backtrace.first(5))
      
      message = @slack_responder.error_message(
        text: '❌ Something went wrong. Please try again.'
      )
      
      @slack_responder.post_to_response_url(
        response_url: response_url,
        payload: message
      )
    end
  end
end
