# Slack /meet Command - Complete Implementation Specification

## Document Purpose

This specification provides all details necessary for autonomous implementation of a Slack slash command (`/meet`) that creates Google Meet links. The implementation should follow these specifications exactly, proceeding through units of work sequentially, testing thoroughly, and committing after each unit.

---

## Project Overview

### What We're Building

A Ruby/Sinatra web application deployed on Fly.io that:

1. **Receives `/meet [optional-name]` slash commands from Slack**
2. **Creates a new Google Meet link** via Google Meet REST API
3. **Posts the meeting link** back to the Slack channel/DM where the command was invoked
4. **Supports multi-tenant OAuth** - any user from any organization can authenticate with their Google account

### Key Constraints

- **Response Time**: Slack requires a response within 3 seconds. The app must respond immediately with an acknowledgment, then process the Google API call asynchronously and post the result back via `response_url`.
- **No Auto-Browser Open**: Slack commands are server-side; cannot automatically open user's browser. Users click the link/button to join.
- **Code Quality**: Clarity, correctness, and maintainability over performance. Clean architecture, YARD documentation, meaningful names.

---

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Language | Ruby | 3.2+ |
| Web Framework | Sinatra | Latest |
| Web Server | Puma | Latest |
| Database | SQLite | 3.x |
| ORM | Sequel | Latest |
| Google API | google-apis-meet_v2 | Latest |
| Google Auth | googleauth | Latest |
| HTTP Client | Net::HTTP (stdlib) | - |
| Testing | Minitest | Latest |
| Mocking | WebMock | Latest |
| Linting | RuboCop | Latest |
| Deployment | Fly.io | - |

### Fly.io Configuration

- **Machine Size**: shared-cpu-1x
- **Memory**: 256MB
- **Always On**: `auto_stop_machines = false`, `min_machines_running = 1`
- **Volume**: 1GB persistent volume mounted at `/data` for SQLite

---

## Project Structure

```
slack-meet-command/
├── .devcontainer/
│   ├── devcontainer.json           # VS Code devcontainer configuration
│   ├── README.md                   # Devcontainer setup and usage guide
│   └── specs.md                    # This specification document
│
├── requirements/                   # Requirements documentation
│   ├── README.md                   # Overview of requirements organization
│   ├── core/
│   │   ├── REQ-001-create-meet-link.md
│   │   ├── REQ-002-post-to-channel.md
│   │   └── REQ-003-optional-meeting-name.md
│   ├── configuration/
│   │   ├── REQ-010-default-config.md
│   │   ├── REQ-011-transcription.md
│   │   ├── REQ-012-recording.md
│   │   ├── REQ-013-smart-notes.md
│   │   ├── REQ-014-access-type.md
│   │   └── REQ-015-moderation.md
│   ├── authentication/
│   │   ├── REQ-020-google-oauth.md
│   │   ├── REQ-021-token-storage.md
│   │   └── REQ-022-token-refresh.md
│   ├── slack/
│   │   ├── REQ-030-signature-verification.md
│   │   ├── REQ-031-three-second-response.md
│   │   └── REQ-032-async-callback.md
│   └── operations/
│       ├── REQ-040-health-endpoint.md
│       └── REQ-041-error-handling.md
│
├── app.rb                          # Sinatra routes (thin routing layer)
├── config.ru                       # Rack configuration
├── config.json                     # Default meeting configuration
├── Gemfile                         # Ruby dependencies
├── Gemfile.lock                    # Locked dependency versions
├── Rakefile                        # Rake tasks (db:migrate, test, etc.)
├── README.md                       # Project overview and quick start
├── DEPLOYMENT.md                   # Step-by-step deployment guide
│
├── .env.example                    # Template for environment variables
├── .gitignore                      # Git ignore patterns
├── .rubocop.yml                    # RuboCop configuration
│
├── app/
│   ├── services/
│   │   ├── meet_command_handler.rb # Orchestrates /meet command flow
│   │   ├── meeting_creator.rb      # Creates Google Meet spaces
│   │   └── google_auth_handler.rb  # Manages OAuth flow
│   └── models/
│       └── user_token.rb           # Sequel model for OAuth tokens
│
├── lib/
│   ├── async_job_runner.rb         # Background thread execution
│   ├── configuration.rb            # Loads and validates config.json
│   ├── errors.rb                   # Custom exception classes
│   ├── google_auth_client.rb       # Google OAuth operations
│   ├── google_meet_client.rb       # Google Meet API wrapper
│   ├── logger_factory.rb           # Environment-aware logger
│   ├── slack_request_verifier.rb   # Slack signature verification
│   ├── slack_responder.rb          # Slack message formatting/posting
│   └── token_store.rb              # Token CRUD operations
│
├── db/
│   ├── connection.rb               # Sequel database connection
│   └── migrations/
│       └── 001_create_user_tokens.rb
│
├── test/
│   ├── README.md                   # Test organization and running guide
│   ├── test_helper.rb              # Common test setup
│   ├── requirements/               # Functional tests (mirror /requirements)
│   │   ├── core/
│   │   │   ├── req_001_create_meet_link_test.rb
│   │   │   ├── req_002_post_to_channel_test.rb
│   │   │   └── req_003_optional_meeting_name_test.rb
│   │   ├── configuration/
│   │   │   ├── req_010_default_config_test.rb
│   │   │   ├── req_011_transcription_test.rb
│   │   │   ├── req_012_recording_test.rb
│   │   │   ├── req_013_smart_notes_test.rb
│   │   │   ├── req_014_access_type_test.rb
│   │   │   └── req_015_moderation_test.rb
│   │   ├── authentication/
│   │   │   ├── req_020_google_oauth_test.rb
│   │   │   ├── req_021_token_storage_test.rb
│   │   │   └── req_022_token_refresh_test.rb
│   │   ├── slack/
│   │   │   ├── req_030_signature_verification_test.rb
│   │   │   ├── req_031_three_second_response_test.rb
│   │   │   └── req_032_async_callback_test.rb
│   │   └── operations/
│   │       ├── req_040_health_endpoint_test.rb
│   │       └── req_041_error_handling_test.rb
│   ├── integration/
│   │   └── endpoints_test.rb       # Black-box endpoint tests
│   └── support/
│       ├── api_mocks.rb            # WebMock helpers for Google/Slack
│       └── factory_helpers.rb      # Test data builders
│
├── Dockerfile                      # Container image definition
├── fly.toml                        # Fly.io deployment configuration
└── .dockerignore                   # Docker build exclusions
```

---

## Requirements Specifications

### Core Requirements

#### REQ-001: Create Google Meet Link

**Description**: When a user invokes `/meet`, the system creates a new Google Meet space via the Google Meet REST API.

**Acceptance Criteria**:
- Calls `spaces.create` endpoint on Google Meet API
- Uses the user's stored OAuth credentials
- Returns a valid `meeting_uri` (e.g., `https://meet.google.com/abc-defg-hij`)
- Applies configuration options from `config.json`

**API Details**:
- Endpoint: `POST https://meet.googleapis.com/v2/spaces`
- Scope: `https://www.googleapis.com/auth/meetings.space.created`
- Returns: `{ name: "spaces/xxx", meetingUri: "https://...", meetingCode: "abc-defg-hij" }`

---

#### REQ-002: Post Link to Channel

**Description**: After creating the meeting, post the link back to the Slack channel or DM where the command was invoked.

**Acceptance Criteria**:
- Posts to Slack via `response_url` (async callback)
- Uses `response_type: "in_channel"` so all channel members see it
- Message includes:
  - Meeting name (if provided) or "New Meeting"
  - Clickable meeting link
  - "Join Meeting" button (Block Kit)
- Message format is visually clear and professional

**Block Kit Response Structure**:
```json
{
  "response_type": "in_channel",
  "replace_original": true,
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "🎥 *<meeting_name>*\n<meeting_uri>"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": { "type": "plain_text", "text": "Join Meeting", "emoji": true },
          "url": "<meeting_uri>",
          "style": "primary"
        }
      ]
    }
  ]
}
```

---

#### REQ-003: Optional Meeting Name

**Description**: Users can optionally provide a meeting name as an argument to the command.

**Acceptance Criteria**:
- `/meet` creates meeting with default name "New Meeting"
- `/meet standup` creates meeting with name "standup"
- `/meet weekly sync` creates meeting with name "weekly sync"
- Meeting name appears in the Slack message (Google API doesn't support custom titles)
- Empty/whitespace-only text treated as no name provided

---

### Configuration Requirements

#### REQ-010: Default Configuration

**Description**: Load default meeting settings from `config.json` at application startup.

**config.json Structure**:
```json
{
  "access_type": "TRUSTED",
  "auto_transcribe": false,
  "auto_record": false,
  "smart_notes": false,
  "moderation": "OFF"
}
```

**Acceptance Criteria**:
- Config loaded once at startup
- Missing file raises clear error with setup instructions
- Invalid JSON raises clear parse error
- Missing keys use hardcoded defaults
- Environment variables can override config values:
  - `MEET_ACCESS_TYPE`
  - `MEET_AUTO_TRANSCRIBE`
  - `MEET_AUTO_RECORD`
  - `MEET_SMART_NOTES`
  - `MEET_MODERATION`

---

#### REQ-011: Auto-Transcription Option

**Description**: Configure whether meetings have auto-transcription enabled.

**Acceptance Criteria**:
- When `auto_transcribe: true`, sets `artifactConfig.transcriptionConfig.autoTranscriptionGeneration: "ON"`
- When `auto_transcribe: false`, sets value to `"OFF"`
- Requires Google Workspace account (may silently fail for consumer accounts)

---

#### REQ-012: Auto-Recording Option

**Description**: Configure whether meetings have auto-recording enabled.

**Acceptance Criteria**:
- When `auto_record: true`, sets `artifactConfig.recordingConfig.autoRecordingGeneration: "ON"`
- When `auto_record: false`, sets value to `"OFF"`
- Requires Google Workspace account

---

#### REQ-013: Smart Notes Option

**Description**: Configure whether meetings have AI-generated smart notes enabled.

**Acceptance Criteria**:
- When `smart_notes: true`, sets `artifactConfig.smartNotesConfig.autoSmartNotesGeneration: "ON"`
- When `smart_notes: false`, sets value to `"OFF"`
- Requires Google Workspace account

---

#### REQ-014: Access Type Option

**Description**: Configure who can join meetings without knocking.

**Accepted Values**:
- `"OPEN"`: Anyone with link joins without knocking
- `"TRUSTED"`: Org members + invited externals join without knocking; others knock
- `"RESTRICTED"`: Only invitees join without knocking; everyone else knocks

**Acceptance Criteria**:
- Sets `config.accessType` on space creation
- Invalid values raise configuration error at startup
- Default is `"TRUSTED"`

---

#### REQ-015: Moderation Option

**Description**: Configure meeting moderation mode.

**Accepted Values**:
- `"OFF"`: Moderation disabled
- `"ON"`: Moderation enabled (host has more control)

**Acceptance Criteria**:
- Sets `config.moderation` on space creation
- Default is `"OFF"`

---

### Authentication Requirements

#### REQ-020: Google OAuth Flow

**Description**: Implement OAuth 2.0 flow for users to authenticate with Google.

**Flow**:
1. User invokes `/meet` without stored token
2. App returns ephemeral message with "Connect Google Account" button
3. Button links to `/auth/google?state=<encoded_slack_user_id>`
4. User authenticates with Google, grants permissions
5. Google redirects to `/auth/google/callback?code=<code>&state=<state>`
6. App exchanges code for tokens, stores them
7. User sees success page, can retry `/meet`

**Acceptance Criteria**:
- OAuth consent requests only `meetings.space.created` scope
- Uses `access_type: "offline"` to receive refresh token
- Uses `prompt: "consent"` to ensure refresh token on first auth
- State parameter prevents CSRF attacks
- Handles OAuth errors gracefully (user denies, invalid code, etc.)

**Endpoints**:
- `GET /auth/google` - Initiates OAuth flow
- `GET /auth/google/callback` - Handles OAuth callback

---

#### REQ-021: Token Storage

**Description**: Persist OAuth tokens in SQLite database.

**Schema**:
```sql
CREATE TABLE user_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slack_user_id VARCHAR(50) NOT NULL UNIQUE,
  slack_team_id VARCHAR(50) NOT NULL,
  google_access_token TEXT NOT NULL,
  google_refresh_token TEXT,
  google_token_expiry TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_tokens_slack_user_id ON user_tokens(slack_user_id);
```

**Acceptance Criteria**:
- Tokens stored with `slack_user_id` as unique key
- Both access and refresh tokens stored
- Token expiry timestamp stored for refresh logic
- Tokens can be updated (re-authorization)
- Tokens can be deleted (disconnect account)

---

#### REQ-022: Token Refresh

**Description**: Automatically refresh expired access tokens.

**Acceptance Criteria**:
- Before API call, check if `google_token_expiry` is within 5 minutes
- If expiring soon, use refresh token to get new access token
- Update stored tokens with new access token and expiry
- If refresh fails (revoked), delete stored tokens and prompt re-auth
- Handle case where refresh token is missing (prompt re-auth)

---

### Slack Requirements

#### REQ-030: Signature Verification

**Description**: Verify all incoming Slack requests using HMAC signature.

**Algorithm**:
1. Extract `X-Slack-Request-Timestamp` header
2. Check timestamp is within 5 minutes of current time (prevent replay)
3. Construct signature base string: `v0:{timestamp}:{request_body}`
4. Compute HMAC-SHA256 using `SLACK_SIGNING_SECRET`
5. Compare with `X-Slack-Signature` header (constant-time comparison)

**Acceptance Criteria**:
- Invalid signature returns 403 Forbidden
- Expired timestamp (> 5 min old) returns 403 Forbidden
- Missing headers return 403 Forbidden
- All `/slack/*` endpoints verify signature
- Health endpoint does NOT require signature

---

#### REQ-031: Three-Second Response

**Description**: Respond to Slack within 3 seconds to avoid timeout.

**Acceptance Criteria**:
- Immediately return 200 OK with acknowledgment message
- Acknowledgment is ephemeral: `{ "response_type": "ephemeral", "text": "⏳ Creating meeting..." }`
- Actual work happens in background thread
- Result posted via `response_url` (async)

---

#### REQ-032: Async Callback

**Description**: Post meeting result to Slack via `response_url`.

**Acceptance Criteria**:
- Use `response_url` from original request payload
- POST JSON with `Content-Type: application/json`
- Include `replace_original: true` to replace "Creating meeting..." message
- Handle HTTP errors gracefully (log, don't crash)
- `response_url` is valid for 30 minutes

---

### Operations Requirements

#### REQ-040: Health Endpoint

**Description**: Provide health check endpoint for monitoring.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2026-01-29T12:00:00Z"
}
```

**Acceptance Criteria**:
- Returns 200 OK when app is healthy
- No authentication required
- Used by Fly.io for health checks

---

#### REQ-041: Error Handling

**Description**: Handle all error cases gracefully with user-friendly messages.

**Error Cases**:

| Scenario | Slack Response |
|----------|----------------|
| User not authenticated | Ephemeral message with auth button |
| Google token expired, refresh failed | Ephemeral message with re-auth button |
| Google API error | Ephemeral "❌ Failed to create meeting. Please try again." |
| Google API quota exceeded | Ephemeral "❌ Service temporarily unavailable. Please try again later." |
| Invalid Slack signature | 403 Forbidden (no JSON) |
| Unknown error | Ephemeral "❌ Something went wrong. Please try again." + log error |

**Acceptance Criteria**:
- Users never see stack traces or technical errors
- All errors logged with context for debugging
- Errors in background thread don't crash the app
- Errors posted back to Slack via `response_url`

---

## Code Quality Standards

### Architecture Principles

1. **Single Responsibility**: Each class does one thing
   - `MeetingCreator` only creates meetings
   - `TokenStore` only manages tokens
   - `SlackResponder` only formats/sends Slack messages

2. **Dependency Injection**: Dependencies passed via constructor
   ```ruby
   class MeetCommandHandler
     def initialize(token_store:, meeting_creator:, slack_responder:)
       @token_store = token_store
       @meeting_creator = meeting_creator
       @slack_responder = slack_responder
     end
   end
   ```

3. **No Global State**: Avoid class variables, prefer instance state

4. **Explicit Over Implicit**: Clear method signatures, no magic

### Documentation Standards

Every public class and method must have YARD documentation:

```ruby
# Creates Google Meet spaces using the Meet REST API.
#
# @example
#   client = GoogleMeetClient.new(credentials: oauth_credentials)
#   result = client.create_space(config: { access_type: "TRUSTED" })
#   result[:meeting_uri] # => "https://meet.google.com/abc-defg-hij"
#
class GoogleMeetClient
  # Creates a new Google Meet space.
  #
  # @param config [Hash] Meeting configuration options
  # @option config [String] :access_type ("TRUSTED") Who can join without knocking
  # @option config [Boolean] :auto_transcribe (false) Enable auto-transcription
  # @option config [Boolean] :auto_record (false) Enable auto-recording
  # @return [Hash] Meeting details with :meeting_uri and :meeting_code
  # @raise [GoogleApiError] If the API call fails
  def create_space(config: {})
    # ...
  end
end
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase, noun | `MeetingCreator`, `TokenStore` |
| Methods | snake_case, verb | `create_space`, `verify_signature!` |
| Predicates | end with `?` | `token_expired?`, `authenticated?` |
| Dangerous methods | end with `!` | `verify_signature!`, `refresh_token!` |
| Constants | SCREAMING_SNAKE | `DEFAULT_ACCESS_TYPE` |
| Files | snake_case | `meeting_creator.rb` |

### Error Handling

Define custom exceptions in `lib/errors.rb`:

```ruby
module SlackMeet
  module Errors
    # Base error class for all application errors
    class BaseError < StandardError; end

    # Raised when Slack request signature verification fails
    class SlackVerificationError < BaseError; end

    # Raised when user is not authenticated with Google
    class NotAuthenticatedError < BaseError; end

    # Raised when Google token refresh fails
    class TokenRefreshError < BaseError; end

    # Raised when Google API returns an error
    class GoogleApiError < BaseError
      attr_reader :status_code, :error_code

      def initialize(message, status_code: nil, error_code: nil)
        super(message)
        @status_code = status_code
        @error_code = error_code
      end
    end

    # Raised when configuration is invalid
    class ConfigurationError < BaseError; end
  end
end
```

### Logging

Use `LoggerFactory` for environment-aware logging:

```ruby
# Development: Human-readable
# [2026-01-29 12:00:00] INFO  Meeting created | meeting_code=abc-defg-hij user_id=U123

# Production (RACK_ENV=production): JSON
# {"timestamp":"2026-01-29T12:00:00Z","level":"INFO","message":"Meeting created","meeting_code":"abc-defg-hij","user_id":"U123"}
```

Log levels:
- `DEBUG`: Detailed debugging info (only in development)
- `INFO`: Normal operations (meeting created, user authenticated)
- `WARN`: Recoverable issues (token refresh, retry)
- `ERROR`: Failures requiring attention (API errors, unexpected exceptions)

---

## Testing Strategy

### Test Categories

#### Functional Tests (`test/requirements/`)

Test that requirements are met. Mock all external APIs.

```ruby
# test/requirements/core/req_001_create_meet_link_test.rb
class Req001CreateMeetLinkTest < Minitest::Test
  def setup
    # Setup mocks
  end

  def test_creates_google_meet_space_via_api
    # Given a user with valid Google credentials
    # When they invoke /meet
    # Then a Google Meet space is created via the API
  end

  def test_returns_valid_meeting_uri
    # Given a successful API call
    # Then the result contains a valid https://meet.google.com/... URI
  end

  def test_applies_configuration_options
    # Given config.json with auto_transcribe: true
    # When creating a meeting
    # Then the API request includes transcription config
  end
end
```

#### Integration Tests (`test/integration/`)

Test endpoints as a black box. Verify HTTP status, headers, JSON schema.

```ruby
# test/integration/endpoints_test.rb
class EndpointsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_health_returns_200_with_json
    get '/health'

    assert_equal 200, last_response.status
    assert_equal 'application/json', last_response.content_type
    
    body = JSON.parse(last_response.body)
    assert_equal 'ok', body['status']
    assert body.key?('timestamp')
  end

  def test_slack_meet_requires_valid_signature
    post '/slack/meet', {}

    assert_equal 403, last_response.status
  end

  def test_slack_meet_returns_immediate_acknowledgment
    post '/slack/meet', valid_slack_payload, valid_slack_headers

    assert_equal 200, last_response.status
    body = JSON.parse(last_response.body)
    assert_equal 'ephemeral', body['response_type']
  end
end
```

### Mocking Strategy

Use WebMock to mock all external HTTP calls:

```ruby
# test/support/api_mocks.rb
module ApiMocks
  def stub_google_meet_create_space(meeting_uri: "https://meet.google.com/abc-defg-hij")
    stub_request(:post, "https://meet.googleapis.com/v2/spaces")
      .to_return(
        status: 200,
        body: {
          name: "spaces/abc123",
          meetingUri: meeting_uri,
          meetingCode: "abc-defg-hij"
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_google_token_refresh(access_token: "new_access_token")
    stub_request(:post, "https://oauth2.googleapis.com/token")
      .to_return(
        status: 200,
        body: {
          access_token: access_token,
          expires_in: 3600,
          token_type: "Bearer"
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_slack_response_url(response_url)
    stub_request(:post, response_url)
      .to_return(status: 200, body: "ok")
  end
end
```

### Test Data Builders

```ruby
# test/support/factory_helpers.rb
module FactoryHelpers
  def build_slack_payload(overrides = {})
    {
      'token' => 'test_token',
      'team_id' => 'T12345',
      'team_domain' => 'testteam',
      'channel_id' => 'C12345',
      'channel_name' => 'general',
      'user_id' => 'U12345',
      'user_name' => 'testuser',
      'command' => '/meet',
      'text' => '',
      'response_url' => 'https://hooks.slack.com/commands/T12345/12345/abcdef',
      'trigger_id' => '12345.12345.abcdef'
    }.merge(overrides)
  end

  def build_slack_headers(payload, signing_secret: ENV['SLACK_SIGNING_SECRET'] || 'test_secret')
    timestamp = Time.now.to_i.to_s
    body = URI.encode_www_form(payload)
    sig_basestring = "v0:#{timestamp}:#{body}"
    signature = 'v0=' + OpenSSL::HMAC.hexdigest('SHA256', signing_secret, sig_basestring)

    {
      'HTTP_X_SLACK_REQUEST_TIMESTAMP' => timestamp,
      'HTTP_X_SLACK_SIGNATURE' => signature,
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    }
  end
end
```

### Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/requirements/core/req_001_create_meet_link_test.rb

# Run with verbose output
bundle exec rake test TESTOPTS="--verbose"
```

---

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SLACK_SIGNING_SECRET` | Slack app signing secret | `abc123...` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | `123...apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | `GOCSPX-...` |
| `APP_URL` | Public URL of the app | `https://slack-meet.fly.dev` |
| `SESSION_SECRET` | Secret for session encryption | `64-char-random-hex` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | SQLite database path | `sqlite://db/development.sqlite3` |
| `RACK_ENV` | Environment (development/production) | `development` |
| `MEET_ACCESS_TYPE` | Override config.json | - |
| `MEET_AUTO_TRANSCRIBE` | Override config.json | - |
| `MEET_AUTO_RECORD` | Override config.json | - |
| `MEET_SMART_NOTES` | Override config.json | - |
| `MEET_MODERATION` | Override config.json | - |

### .env.example

```bash
# Slack Configuration
SLACK_SIGNING_SECRET=your_slack_signing_secret_here

# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Application Configuration
APP_URL=http://localhost:9292
SESSION_SECRET=generate_with_ruby_securerandom_hex_64
DATABASE_URL=sqlite://db/development.sqlite3
RACK_ENV=development

# Optional: Override config.json defaults
# MEET_ACCESS_TYPE=TRUSTED
# MEET_AUTO_TRANSCRIBE=false
# MEET_AUTO_RECORD=false
# MEET_SMART_NOTES=false
# MEET_MODERATION=OFF
```

---

## Units of Work

Each unit should be implemented, tested, and committed before proceeding to the next.

### Unit 1: Project Scaffolding & Requirements

**Create**:
- `.devcontainer/devcontainer.json`
- `.devcontainer/README.md`
- `requirements/` folder with all requirement markdown files
- `test/README.md`
- `test/test_helper.rb` (basic setup)
- `test/support/api_mocks.rb` (empty module)
- `test/support/factory_helpers.rb` (empty module)
- `.env.example`
- `.gitignore`
- `.rubocop.yml`
- `Gemfile`
- `Rakefile` (with test task)
- `README.md` (placeholder)
- `DEPLOYMENT.md` (placeholder)
- `config.json`
- `app.rb` (empty Sinatra app)
- `config.ru`

**Verify**: `bundle install` succeeds, `bundle exec rake test` runs (0 tests)

**Commit**: `Initial scaffolding with requirements documentation`

---

### Unit 2: Configuration Module

**Create**:
- `lib/configuration.rb`
- `test/requirements/configuration/req_010_default_config_test.rb`

**Implementation Details**:
- Singleton pattern or class methods
- Load `config.json` from project root
- Validate required keys
- Support environment variable overrides
- Raise `ConfigurationError` with helpful message on failure

**Tests**:
- Loads valid config.json
- Raises on missing file
- Raises on invalid JSON
- Uses defaults for missing keys
- Environment variables override config values

**Verify**: All tests pass

**Commit**: `Add Configuration module (REQ-010)`

---

### Unit 3: Logging Setup

**Create**:
- `lib/logger_factory.rb`
- `test/unit/logger_factory_test.rb`

**Implementation Details**:
- `LoggerFactory.create` returns configured Logger
- Human-readable format in development
- JSON format in production
- Include timestamp, level, message, optional context

**Tests**:
- Returns Logger instance
- Development format is human-readable
- Production format is JSON
- Context included in output

**Verify**: All tests pass

**Commit**: `Add LoggerFactory with environment-aware formatting`

---

### Unit 4: Database & Token Storage

**Create**:
- `db/connection.rb`
- `db/migrations/001_create_user_tokens.rb`
- `app/models/user_token.rb`
- `lib/token_store.rb`
- `lib/errors.rb`
- Update `Rakefile` with `db:migrate` task
- `test/requirements/authentication/req_021_token_storage_test.rb`

**Implementation Details**:
- Sequel connection setup with SQLite
- Migration with proper indexes
- `TokenStore` class with clean interface:
  - `find_by_slack_user(slack_user_id)`
  - `store_tokens(slack_user_id:, slack_team_id:, access_token:, refresh_token:, expires_at:)`
  - `update_access_token(slack_user_id:, access_token:, expires_at:)`
  - `delete_for_user(slack_user_id)`
  - `token_expiring_soon?(slack_user_id)` - within 5 minutes

**Tests**:
- Store and retrieve tokens
- Update existing tokens
- Delete tokens
- Detect expiring tokens
- Handle missing user

**Verify**: All tests pass, `bundle exec rake db:migrate` works

**Commit**: `Add database and TokenStore (REQ-021)`

---

### Unit 5: Slack Request Verifier

**Create**:
- `lib/slack_request_verifier.rb`
- Add `SlackVerificationError` to `lib/errors.rb`
- `test/requirements/slack/req_030_signature_verification_test.rb`

**Implementation Details**:
- `SlackRequestVerifier.verify!(request, signing_secret:)`
- Extract timestamp and signature from headers
- Validate timestamp freshness (5 minute window)
- Compute and compare HMAC signature
- Use constant-time comparison (`Rack::Utils.secure_compare`)
- Raise `SlackVerificationError` on any failure

**Tests**:
- Valid signature passes
- Invalid signature raises error
- Expired timestamp raises error
- Missing headers raise error

**Verify**: All tests pass

**Commit**: `Add SlackRequestVerifier (REQ-030)`

---

### Unit 6: Slack Responder

**Create**:
- `lib/slack_responder.rb`
- `test/requirements/core/req_002_post_to_channel_test.rb`
- `test/requirements/slack/req_032_async_callback_test.rb`
- Update `test/support/api_mocks.rb`

**Implementation Details**:
- `SlackResponder` class with methods:
  - `immediate_acknowledgment` - returns Hash for immediate response
  - `meeting_created_message(meeting_name:, meeting_uri:)` - returns Block Kit Hash
  - `auth_required_message(auth_url:)` - returns Hash with auth button
  - `error_message(text:)` - returns ephemeral error Hash
  - `post_to_response_url(response_url:, payload:)` - POSTs to Slack

**Tests**:
- `immediate_acknowledgment` returns correct structure
- `meeting_created_message` includes all required blocks
- `post_to_response_url` makes HTTP POST (mocked)
- Error message is ephemeral

**Verify**: All tests pass

**Commit**: `Add SlackResponder (REQ-002, REQ-032)`

---

### Unit 7: Google Clients (Mocked)

**Create**:
- `lib/google_auth_client.rb`
- `lib/google_meet_client.rb`
- Add `GoogleApiError`, `NotAuthenticatedError`, `TokenRefreshError` to `lib/errors.rb`
- `test/requirements/authentication/req_020_google_oauth_test.rb`
- Update `test/support/api_mocks.rb`

**Implementation Details**:

`GoogleAuthClient`:
- `authorization_url(state:, redirect_uri:)` - returns Google OAuth URL
- `exchange_code(code:, redirect_uri:)` - exchanges code for tokens
- `refresh_access_token(refresh_token:)` - refreshes access token
- Mock all HTTP calls in tests

`GoogleMeetClient`:
- `create_space(access_token:, config:)` - creates Meet space
- Returns `{ meeting_uri:, meeting_code:, space_name: }`
- Mock all HTTP calls in tests

**Tests**:
- Auth URL includes correct scopes and parameters
- Code exchange returns tokens (mocked)
- Token refresh returns new token (mocked)
- Create space returns meeting info (mocked)
- API errors raise `GoogleApiError`

**Verify**: All tests pass

**Commit**: `Add Google API clients with mock support (REQ-020)`

---

### Unit 8: Meeting Creator Service

**Create**:
- `app/services/meeting_creator.rb`
- `test/requirements/core/req_001_create_meet_link_test.rb`
- `test/requirements/core/req_003_optional_meeting_name_test.rb`
- `test/requirements/configuration/req_011_transcription_test.rb`
- `test/requirements/configuration/req_012_recording_test.rb`
- `test/requirements/configuration/req_013_smart_notes_test.rb`
- `test/requirements/configuration/req_014_access_type_test.rb`
- `test/requirements/configuration/req_015_moderation_test.rb`

**Implementation Details**:
- `MeetingCreator` class
- Constructor takes `google_meet_client:`, `configuration:`
- `create(access_token:, meeting_name: nil)` method
- Builds config from Configuration, passes to client
- Returns `{ meeting_uri:, meeting_code:, meeting_name: }`

**Tests**:
- Creates meeting via client
- Uses configuration options
- Meeting name passed through (or default)
- All config options applied to API request

**Verify**: All tests pass

**Commit**: `Add MeetingCreator service (REQ-001, REQ-003, REQ-011-015)`

---

### Unit 9: Async Job Runner

**Create**:
- `lib/async_job_runner.rb`
- `test/requirements/slack/req_031_three_second_response_test.rb`

**Implementation Details**:
- `AsyncJobRunner.perform_async(logger:) { block }`
- Spawns new Thread
- Wraps block in error handling
- Logs any exceptions
- Does not re-raise (thread dies silently with log)

**Tests**:
- Block executes asynchronously
- Errors are logged, not raised
- Main thread continues immediately

**Verify**: All tests pass

**Commit**: `Add AsyncJobRunner (REQ-031)`

---

### Unit 10: Token Refresh

**Update**:
- `lib/token_store.rb`
- `lib/google_auth_client.rb`
- `test/requirements/authentication/req_022_token_refresh_test.rb`

**Implementation Details**:
- `TokenStore#refresh_if_needed(slack_user_id, google_auth_client:)`
- Checks if token expiring within 5 minutes
- If so, calls `google_auth_client.refresh_access_token`
- Updates stored token
- Returns current valid access token
- Raises `TokenRefreshError` if refresh fails

**Tests**:
- Fresh token not refreshed
- Expiring token triggers refresh
- Refresh updates stored token
- Failed refresh raises error

**Verify**: All tests pass

**Commit**: `Add token refresh handling (REQ-022)`

---

### Unit 11: Meet Command Handler

**Create**:
- `app/services/meet_command_handler.rb`
- `test/requirements/operations/req_041_error_handling_test.rb`

**Implementation Details**:
- `MeetCommandHandler` class
- Constructor injection: `token_store:`, `meeting_creator:`, `slack_responder:`, `google_auth_client:`, `async_job_runner:`, `logger:`
- `call(params)` method:
  1. Check for stored token
  2. If no token, return auth required message immediately
  3. If token exists, return acknowledgment and spawn async job
  4. Async job: refresh token if needed, create meeting, post result
  5. Handle all errors, post error message to response_url

**Tests**:
- User without token gets auth message
- User with token gets acknowledgment
- Successful meeting posted to response_url
- API error posts error message
- Token refresh error prompts re-auth

**Verify**: All tests pass

**Commit**: `Add MeetCommandHandler with error handling (REQ-041)`

---

### Unit 12: Google Auth Handler

**Create**:
- `app/services/google_auth_handler.rb`
- Update `test/requirements/authentication/req_020_google_oauth_test.rb`

**Implementation Details**:
- `GoogleAuthHandler` class
- Constructor: `google_auth_client:`, `token_store:`, `configuration:`
- `authorization_url(slack_user_id:, slack_team_id:)` - generates URL with encoded state
- `handle_callback(code:, state:)` - decodes state, exchanges code, stores tokens
- State includes `slack_user_id` and `slack_team_id` (JSON, base64 encoded)

**Tests**:
- Authorization URL is valid
- State encodes user info
- Callback stores tokens
- Invalid state raises error
- Invalid code raises error

**Verify**: All tests pass

**Commit**: `Add GoogleAuthHandler for OAuth flow`

---

### Unit 13: Sinatra App & Health Endpoint

**Create/Update**:
- `app.rb` (full implementation)
- `config.ru`
- `test/requirements/operations/req_040_health_endpoint_test.rb`
- `test/integration/endpoints_test.rb`

**Implementation Details**:
- Wire up all dependencies at startup
- Routes:
  - `GET /health` - health check
  - `POST /slack/meet` - slash command
  - `GET /auth/google` - initiate OAuth
  - `GET /auth/google/callback` - OAuth callback
- Thin routing layer, delegates to handlers
- Error handling middleware for uncaught exceptions

**Tests**:
- Health returns 200 with JSON
- Slack meet requires signature
- Slack meet with valid signature returns 200
- Auth google redirects to Google
- Auth callback stores tokens

**Verify**: All tests pass

**Commit**: `Add Sinatra routes and health endpoint (REQ-040)`

---

### Unit 14: Integration Test Suite

**Update**:
- `test/integration/endpoints_test.rb`
- `test/support/api_mocks.rb`
- `test/support/factory_helpers.rb`

**Tests to Add**:
- Full /meet flow with mocked Google API
- OAuth flow end-to-end
- Error scenarios (API failure, invalid signature)
- JSON schema validation for all responses
- Header validation (Content-Type, etc.)

**Verify**: All tests pass

**Commit**: `Complete integration test suite`

---

### Unit 15: Fly.io Deployment Config

**Create**:
- `Dockerfile`
- `fly.toml`
- `.dockerignore`

**Dockerfile Details**:
```dockerfile
FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

RUN bundle exec rake db:migrate

EXPOSE 8080
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

**fly.toml Details**:
```toml
app = "slack-meet-command"
primary_region = "sjc"

[build]

[env]
  RACK_ENV = "production"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "off"
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "connections"
    hard_limit = 25
    soft_limit = 20

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"

[mounts]
  source = "data"
  destination = "/data"

[[http_service.checks]]
  interval = "10s"
  timeout = "2s"
  path = "/health"
```

**Create**: `config/puma.rb`

**Verify**: `docker build .` succeeds

**Commit**: `Add Fly.io deployment configuration`

---

### Unit 16: Complete Documentation

**Complete**:
- `README.md` - project overview, quick start, architecture
- `DEPLOYMENT.md` - step-by-step deployment (see section below)
- `test/README.md` - testing guide
- `.devcontainer/README.md` - devcontainer guide

**Verify**: Documentation is complete and accurate

**Commit**: `Complete all documentation`

---

## DEPLOYMENT.md Content

The deployment guide must include exact, copy-paste-ready commands and step-by-step instructions:

```markdown
# Deployment Guide

Complete step-by-step instructions for deploying the Slack /meet command.

## Prerequisites

- [Fly.io CLI](https://fly.io/docs/hands-on/install-flyctl/) installed
- Google Cloud account with billing enabled
- Slack workspace where you have admin permissions
- Git repository cloned locally

## Step 1: Google Cloud Setup

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name: `slack-meet-command`
4. Click "Create"
5. Wait for project creation, then select it

### 1.2 Enable Google Meet REST API

1. Go to [APIs & Services → Library](https://console.cloud.google.com/apis/library)
2. Search for "Google Meet REST API"
3. Click on it → Click "Enable"

### 1.3 Configure OAuth Consent Screen

1. Go to [APIs & Services → OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent)
2. Select "External" (unless you have Google Workspace)
3. Click "Create"
4. Fill in:
   - App name: `Slack Meet Command`
   - User support email: your email
   - Developer contact: your email
5. Click "Save and Continue"
6. Click "Add or Remove Scopes"
7. Add scope: `https://www.googleapis.com/auth/meetings.space.created`
8. Click "Save and Continue"
9. Add test users (your email) if in testing mode
10. Click "Save and Continue" → "Back to Dashboard"

### 1.4 Create OAuth Credentials

1. Go to [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: "Web application"
4. Name: `Slack Meet Command`
5. Authorized redirect URIs: `https://YOUR_FLY_APP.fly.dev/auth/google/callback`
   (You'll update this after Fly deployment)
6. Click "Create"
7. **Save the Client ID and Client Secret** - you'll need these later

## Step 2: Slack App Setup

### 2.1 Create Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click "Create New App" → "From scratch"
3. App Name: `Meet`
4. Select your workspace
5. Click "Create App"

### 2.2 Add Slash Command

1. In your app settings, go to "Slash Commands"
2. Click "Create New Command"
3. Fill in:
   - Command: `/meet`
   - Request URL: `https://YOUR_FLY_APP.fly.dev/slack/meet`
     (You'll update this after Fly deployment)
   - Short Description: `Create a Google Meet link`
   - Usage Hint: `[meeting name]`
4. Click "Save"

### 2.3 Get Signing Secret

1. Go to "Basic Information"
2. Under "App Credentials", find "Signing Secret"
3. Click "Show" and **save this value**

### 2.4 Install to Workspace

1. Go to "Install App"
2. Click "Install to Workspace"
3. Authorize the app

## Step 3: Fly.io Deployment

### 3.1 Login to Fly.io

```bash
fly auth login
```

### 3.2 Create the App

```bash
cd slack-meet-command
fly launch --no-deploy
```

When prompted:
- App name: choose a unique name (e.g., `slack-meet-yourname`)
- Region: choose closest to you
- Do not set up Postgres or Redis

### 3.3 Create Persistent Volume

```bash
fly volumes create data --size 1 --region YOUR_REGION
```

Replace `YOUR_REGION` with your chosen region (e.g., `sjc`, `iad`, `lhr`).

### 3.4 Set Secrets

```bash
# Generate a session secret
SESSION_SECRET=$(ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")

# Set all secrets
fly secrets set \
  SLACK_SIGNING_SECRET="your_slack_signing_secret" \
  GOOGLE_CLIENT_ID="your_google_client_id" \
  GOOGLE_CLIENT_SECRET="your_google_client_secret" \
  APP_URL="https://YOUR_APP_NAME.fly.dev" \
  SESSION_SECRET="$SESSION_SECRET" \
  DATABASE_URL="sqlite:///data/production.sqlite3"
```

### 3.5 Deploy

```bash
fly deploy
```

### 3.6 Verify Deployment

```bash
# Check app status
fly status

# Check health endpoint
curl https://YOUR_APP_NAME.fly.dev/health
```

Expected response:
```json
{"status":"ok","timestamp":"2026-01-29T12:00:00Z"}
```

## Step 4: Connect Services

### 4.1 Update Slack Request URL

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Select your app
3. Go to "Slash Commands"
4. Edit `/meet` command
5. Update Request URL to: `https://YOUR_APP_NAME.fly.dev/slack/meet`
6. Save

### 4.2 Update Google OAuth Redirect URI

1. Go to [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials)
2. Click on your OAuth 2.0 Client ID
3. Under "Authorized redirect URIs", update to:
   `https://YOUR_APP_NAME.fly.dev/auth/google/callback`
4. Save

## Step 5: Test the Integration

### 5.1 Test /meet Command

1. Open Slack
2. In any channel, type: `/meet test`
3. You should see: "⏳ Creating meeting..."
4. If not authenticated, you'll see "Connect Google Account" button
5. Click the button, complete Google OAuth
6. Try `/meet test` again
7. You should see a meeting link posted to the channel

### 5.2 Verify Meeting Works

1. Click "Join Meeting" button
2. Google Meet should open in browser
3. Verify the meeting is accessible

## Troubleshooting

### "Invalid signature" error

- Verify `SLACK_SIGNING_SECRET` matches your Slack app
- Check that the secret doesn't have extra whitespace

### "Not authenticated" after OAuth

- Verify `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are correct
- Check that redirect URI matches exactly (including https)
- Ensure Google Meet REST API is enabled

### App not responding

```bash
# Check logs
fly logs

# Check if app is running
fly status

# Restart if needed
fly apps restart
```

### Database issues

```bash
# SSH into the app
fly ssh console

# Check database file exists
ls -la /data/

# Run migrations manually if needed
bundle exec rake db:migrate
```

## Updating the App

```bash
# Make changes locally
git add .
git commit -m "Your changes"

# Deploy
fly deploy
```

## Scaling

The default configuration runs one always-on machine. To scale:

```bash
# Add more machines
fly scale count 2

# Upgrade machine size
fly scale vm shared-cpu-2x
```
```

---

## Devcontainer Configuration

### .devcontainer/devcontainer.json

```json
{
  "name": "Slack Meet Command",
  "image": "mcr.microsoft.com/devcontainers/ruby:3.2",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {}
  },
  "postCreateCommand": "bundle install && bundle exec rake db:migrate",
  "customizations": {
    "vscode": {
      "extensions": [
        "Shopify.ruby-lsp",
        "rebornix.ruby",
        "alexcvzz.vscode-sqlite",
        "humao.rest-client"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.tabSize": 2
      }
    }
  },
  "forwardPorts": [9292],
  "remoteEnv": {
    "RACK_ENV": "development"
  }
}
```

---

## Final Checklist

Before considering implementation complete:

- [ ] All 16 units implemented and committed
- [ ] All tests pass (`bundle exec rake test`)
- [ ] RuboCop passes (`bundle exec rubocop`)
- [ ] Docker builds successfully
- [ ] `DEPLOYMENT.md` has exact, tested commands
- [ ] All README files are complete
- [ ] Every requirement has a corresponding test
- [ ] YARD documentation on all public methods
