# REQ-020: Google OAuth Flow

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/authentication/req_020_google_oauth_test.rb`

## Description

Implement OAuth 2.0 flow for users to authenticate with Google.

## Flow

1. User invokes `/meet` without stored token
2. App returns ephemeral message with "Connect Google Account" button
3. Button links to `/auth/google?state=<encoded_slack_user_id>`
4. User authenticates with Google, grants permissions
5. Google redirects to `/auth/google/callback?code=<code>&state=<state>`
6. App exchanges code for tokens, stores them
7. User sees success page, can retry `/meet`

## Acceptance Criteria

- [ ] OAuth consent requests only `meetings.space.created` scope
- [ ] Uses `access_type: "offline"` to receive refresh token
- [ ] Uses `prompt: "consent"` to ensure refresh token on first auth
- [ ] State parameter prevents CSRF attacks
- [ ] Handles OAuth errors gracefully (user denies, invalid code, etc.)

## Endpoints

- `GET /auth/google` - Initiates OAuth flow
- `GET /auth/google/callback` - Handles OAuth callback

## Security

- State parameter encodes Slack user and team IDs
- State is validated on callback to prevent CSRF
- Tokens stored securely in database

## Dependencies

- REQ-021: Token Storage

## Implementation

See `app/services/google_auth_handler.rb` and `lib/google_auth_client.rb`.
