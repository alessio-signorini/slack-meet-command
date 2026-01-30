# REQ-001: Create Google Meet Link

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/core/req_001_create_meet_link_test.rb`

## Description

When a user invokes `/meet`, the system creates a new Google Meet space via the Google Meet REST API.

## Acceptance Criteria

- [ ] Calls `spaces.create` endpoint on Google Meet API
- [ ] Uses the user's stored OAuth credentials
- [ ] Returns a valid `meeting_uri` (e.g., `https://meet.google.com/abc-defg-hij`)
- [ ] Applies configuration options from `config.json`

## API Details

- **Endpoint**: `POST https://meet.googleapis.com/v2/spaces`
- **Scope**: `https://www.googleapis.com/auth/meetings.space.created`
- **Response**: `{ name: "spaces/xxx", meetingUri: "https://...", meetingCode: "abc-defg-hij" }`

## Dependencies

- REQ-020: Google OAuth Flow (for credentials)
- REQ-010: Default Configuration (for meeting options)

## Implementation

See `app/services/meeting_creator.rb` and `lib/google_meet_client.rb`.
