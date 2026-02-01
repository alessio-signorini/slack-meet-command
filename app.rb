require 'sinatra'
require 'json'
require_relative 'lib/logger_factory'
require_relative 'lib/configuration'
require_relative 'lib/slack_request_verifier'
require_relative 'lib/slack_responder'
require_relative 'lib/google_auth_client'
require_relative 'lib/google_meet_client'
require_relative 'lib/token_store'
require_relative 'lib/async_job_runner'
require_relative 'lib/google_analytics_client'
require_relative 'app/services/meeting_creator'
require_relative 'app/services/meet_command_handler'
require_relative 'app/services/google_auth_handler'
require_relative 'db/connection'

# Performance optimizations for Sinatra
configure do
  # Disable X-Cascade header for speed
  set :x_cascade, false
  
  # Disable method override for slight speed gain
  disable :method_override
  
  # Disable static file serving (use reverse proxy in production)
  set :static, false if ENV.fetch('RACK_ENV', 'development') == 'production'
  
  # Reduce session overhead (we don't use sessions)
  disable :sessions
  
  # Enable gzip compression
  use Rack::Deflater, if: ->(env, _status, _headers, _body) {
    env['PATH_INFO'] !~ /\.(png|jpg|jpeg|gif|svg|ico)$/
  }
end

# Initialize dependencies
LOGGER = SlackMeet::LoggerFactory.create
CONFIG = SlackMeet::Configuration.load

GA_CLIENT = SlackMeet::GoogleAnalyticsClient.new(
  measurement_id: ENV['GA_MEASUREMENT_ID'],
  api_secret: ENV['GA_API_SECRET'],
  logger: LOGGER
)

GOOGLE_AUTH_CLIENT = SlackMeet::GoogleAuthClient.new(
  client_id: ENV.fetch('GOOGLE_CLIENT_ID'),
  client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET')
)

GOOGLE_MEET_CLIENT = SlackMeet::GoogleMeetClient.new
TOKEN_STORE = SlackMeet::TokenStore.new
SLACK_RESPONDER = SlackMeet::SlackResponder.new(logger: LOGGER)

MEETING_CREATOR = SlackMeet::MeetingCreator.new(
  google_meet_client: GOOGLE_MEET_CLIENT,
  configuration: CONFIG
)

MEET_COMMAND_HANDLER = SlackMeet::MeetCommandHandler.new(
  token_store: TOKEN_STORE,
  meeting_creator: MEETING_CREATOR,
  slack_responder: SLACK_RESPONDER,
  google_auth_client: GOOGLE_AUTH_CLIENT,
  async_job_runner: SlackMeet::AsyncJobRunner,
  logger: LOGGER,
  ga_client: GA_CLIENT
)

GOOGLE_AUTH_HANDLER = SlackMeet::GoogleAuthHandler.new(
  google_auth_client: GOOGLE_AUTH_CLIENT,
  token_store: TOKEN_STORE,
  configuration: CONFIG
)

# Error handling
error SlackMeet::Errors::SlackVerificationError do
  halt 403, 'Forbidden'
end

error do
  LOGGER.error(message: 'Unhandled error', error: env['sinatra.error'].message)
  halt 500, 'Internal Server Error'
end

# Disable frame protection for homepage so it can be viewed in browsers/iframes
set :protection, except: [:frame_options]

# Helper method to infer base URL from request
helpers do
  def base_url
    "#{request.scheme}://#{request.host_with_port}"
  end
end

# Homepage
get '/' do
  erb :homepage
end

# Terms of Service
get '/terms-of-service' do
  erb :terms_of_service
end

# Privacy Policy
get '/privacy-policy' do
  erb :privacy_policy
end

# OAuth Success
get '/auth/success' do
  erb :oauth_success
end

# OAuth Error
get '/auth/error' do
  erb :oauth_error
end

# Health check endpoint
get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now.utc.iso8601 }.to_json
end

# Capture raw body before Sinatra processes it (for signature verification)
before '/slack/*' do
  request.body.rewind
  @raw_body = request.body.read
  request.body.rewind
end

# Slack /meet command endpoint
post '/slack/meet' do
  # Verify signature with raw body
  SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @raw_body, signing_secret: ENV.fetch('SLACK_SIGNING_SECRET'))
  
  result = MEET_COMMAND_HANDLER.call(params, base_url: base_url)
  
  content_type :json
  result.to_json
end

# Slack interactive components (button clicks)
post '/slack/interactive' do
  # Verify signature with raw body
  SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @raw_body, signing_secret: ENV.fetch('SLACK_SIGNING_SECRET'))
  
  # Slack sends the payload as form-encoded with a 'payload' parameter
  payload = JSON.parse(params['payload'])
  
  # Log the interaction for debugging
  LOGGER.info(message: 'Interactive component received', type: payload['type'], action: payload.dig('actions', 0, 'action_id'))
  
  # For button clicks, we don't need to do anything - the meeting link is already in the message
  # Just acknowledge the interaction
  content_type :json
  {}.to_json
end

# Google OAuth initiation
get '/auth/google' do
  state = params['state']
  halt 400, 'Missing state parameter' unless state
  
  state_data = JSON.parse(Base64.urlsafe_decode64(state))
  
  redirect_uri = "#{base_url}/auth/google/callback"
  auth_url = GOOGLE_AUTH_HANDLER.authorization_url(
    slack_user_id: state_data['slack_user_id'],
    slack_team_id: state_data['slack_team_id'],
    redirect_uri: redirect_uri
  )
  
  redirect auth_url
end

# Google OAuth callback
get '/auth/google/callback' do
  code = params['code']
  state = params['state']
  error_param = params['error']
  
  if error_param
    @error_message = case error_param
    when 'access_denied'
      'You cancelled the authentication process.'
    else
      "Authentication error: #{error_param}"
    end
    @error_details = 'To use the /meet command, you need to connect your Google account.'
    return erb :oauth_error
  end
  
  unless code && state
    @error_message = 'Invalid authentication response.'
    @error_details = 'Please try running the /meet command in Slack again.'
    return erb :oauth_error
  end
  
  begin
    redirect_uri = "#{base_url}/auth/google/callback"
    state_data = GOOGLE_AUTH_HANDLER.handle_callback(code: code, state: state, redirect_uri: redirect_uri)
  
    # Track authentication completion with hashed user identifier
    GA_CLIENT.track_auth_completed(
      user_id: state_data[:slack_user_id],
      team_id: state_data[:slack_team_id]
    )
    
    # Send confirmation message to Slack if we have a pending response_url
    response_url = TOKEN_STORE.get_and_clear_pending_response_url(state_data[:slack_user_id])
    LOGGER.info(message: 'OAuth callback complete', slack_user_id: state_data[:slack_user_id], has_response_url: !response_url.nil?)
    
    if response_url
      confirmation_message = {
        response_type: 'ephemeral',
        replace_original: true,
        text: '✅ Google account connected! Run `/meet` to create your first meeting.'
      }
      
      begin
        SLACK_RESPONDER.post_to_response_url(
          response_url: response_url,
          payload: confirmation_message
        )
        LOGGER.info(message: 'Posted OAuth confirmation to Slack', slack_user_id: state_data[:slack_user_id])
      rescue StandardError => e
        LOGGER.error(message: 'Failed to post OAuth confirmation', error: e.message, slack_user_id: state_data[:slack_user_id])
      end
    end
    
    # Redirect to success page
    redirect '/auth/success'
  rescue SlackMeet::Errors::GoogleApiError => e
    LOGGER.error(message: 'OAuth callback failed', error: e.message)
    @error_message = 'Failed to connect your Google account.'
    @error_details = 'Please try again. If the problem persists, contact your administrator.'
    erb :oauth_error
  rescue StandardError => e
    LOGGER.error(message: 'Unexpected OAuth error', error: e.message)
    @error_message = 'Something went wrong during authentication.'
    @error_details = 'Please try running the /meet command in Slack again.'
    erb :oauth_error
  end
end
