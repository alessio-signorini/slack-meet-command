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
    def initialize(token_store:, meeting_creator:, slack_responder:, google_auth_client:, async_job_runner:, logger:)
      @token_store = token_store
      @meeting_creator = meeting_creator
      @slack_responder = slack_responder
      @google_auth_client = google_auth_client
      @async_job_runner = async_job_runner
      @logger = logger
    end

    # Handle /meet command
    #
    # @param params [Hash] Request parameters from Slack
    # @return [Hash] Immediate acknowledgment message
    def call(params)
      slack_user_id = params['user_id']
      slack_team_id = params['team_id']
      response_url = params['response_url']
      meeting_name = params['text']
      
      # Check for existing token
      token = @token_store.find_by_slack_user(slack_user_id)
      
      unless token
        auth_url = build_auth_url(slack_user_id, slack_team_id)
        return @slack_responder.auth_required_message(auth_url: auth_url)
      end
      
      # Spawn async job to create meeting
      @async_job_runner.perform_async(logger: @logger) do
        process_meeting_creation(token, meeting_name, response_url)
      end
      
      @slack_responder.immediate_acknowledgment
    end

    private

    def build_auth_url(slack_user_id, slack_team_id)
      state = Base64.urlsafe_encode64(JSON.generate({
        slack_user_id: slack_user_id,
        slack_team_id: slack_team_id
      }))
      
      "#{ENV['APP_URL']}/auth/google?state=#{state}"
    end

    def process_meeting_creation(token, meeting_name, response_url)
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
      
      # Post result to Slack
      message = @slack_responder.meeting_created_message(
        meeting_name: result[:meeting_name],
        meeting_uri: result[:meeting_uri]
      )
      
      @slack_responder.post_to_response_url(
        response_url: response_url,
        payload: message
      )
      
      @logger.info(message: 'Meeting created', meeting_code: result[:meeting_code], user_id: token.slack_user_id)
    rescue Errors::TokenRefreshError => e
      @logger.warn(message: 'Token refresh failed', user_id: token.slack_user_id, error: e.message)
      
      # Delete invalid tokens
      @token_store.delete_for_user(token.slack_user_id)
      
      # Prompt re-auth
      auth_url = build_auth_url(token.slack_user_id, token.slack_team_id)
      message = @slack_responder.auth_required_message(auth_url: auth_url)
      
      @slack_responder.post_to_response_url(
        response_url: response_url,
        payload: message
      )
    rescue Errors::GoogleApiError => e
      @logger.error(message: 'Google API error', error: e.message, status_code: e.status_code)
      
      message = @slack_responder.error_message(
        text: '❌ Failed to create meeting. Please try again.'
      )
      
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
