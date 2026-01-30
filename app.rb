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
require_relative 'app/services/meeting_creator'
require_relative 'app/services/meet_command_handler'
require_relative 'app/services/google_auth_handler'
require_relative 'db/connection'

# Initialize dependencies
LOGGER = SlackMeet::LoggerFactory.create
CONFIG = SlackMeet::Configuration.load

GOOGLE_AUTH_CLIENT = SlackMeet::GoogleAuthClient.new(
  client_id: ENV.fetch('GOOGLE_CLIENT_ID'),
  client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET'),
  redirect_uri: "#{ENV.fetch('APP_URL')}/auth/google/callback"
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
  logger: LOGGER
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

# Health check endpoint
get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now.utc.iso8601 }.to_json
end

# Slack /meet command endpoint
post '/slack/meet' do
  SlackMeet::SlackRequestVerifier.verify!(request, signing_secret: ENV.fetch('SLACK_SIGNING_SECRET'))
  
  result = MEET_COMMAND_HANDLER.call(params)
  
  content_type :json
  result.to_json
end

# Google OAuth initiation
get '/auth/google' do
  state = params['state']
  halt 400, 'Missing state parameter' unless state
  
  state_data = JSON.parse(Base64.urlsafe_decode64(state))
  
  auth_url = GOOGLE_AUTH_HANDLER.authorization_url(
    slack_user_id: state_data['slack_user_id'],
    slack_team_id: state_data['slack_team_id']
  )
  
  redirect auth_url
end

# Google OAuth callback
get '/auth/google/callback' do
  code = params['code']
  state = params['state']
  error_param = params['error']
  
  if error_param
    halt 400, "OAuth error: #{error_param}"
  end
  
  halt 400, 'Missing code parameter' unless code
  halt 400, 'Missing state parameter' unless state
  
  GOOGLE_AUTH_HANDLER.handle_callback(code: code, state: state)
  
  <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Authentication Successful</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
               text-align: center; padding: 50px; background: #f5f5f5; }
        .container { background: white; max-width: 500px; margin: 0 auto; padding: 40px; 
                     border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2eb67d; margin-bottom: 20px; }
        p { color: #666; line-height: 1.6; }
        .success-icon { font-size: 64px; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="success-icon">✓</div>
        <h1>Authentication Successful!</h1>
        <p>Your Google account has been connected.</p>
        <p>You can now close this window and return to Slack to use the <code>/meet</code> command.</p>
      </div>
    </body>
    </html>
  HTML
end
