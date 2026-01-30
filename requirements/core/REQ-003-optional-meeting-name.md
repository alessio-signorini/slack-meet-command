# REQ-003: Optional Meeting Name

**Status**: Implemented  
**Priority**: High  
**Test File**: `test/requirements/core/req_003_optional_meeting_name_test.rb`

## Description

Users can optionally provide a meeting name as an argument to the command.

## Acceptance Criteria

- [ ] `/meet` creates meeting with default name "New Meeting"
- [ ] `/meet standup` creates meeting with name "standup"
- [ ] `/meet weekly sync` creates meeting with name "weekly sync"
- [ ] Meeting name appears in the Slack message
- [ ] Empty/whitespace-only text treated as no name provided
- [ ] Note: Google API doesn't support custom titles in the API, so the name is only displayed in Slack

## Examples

| Command | Meeting Name |
|---------|--------------|
| `/meet` | "New Meeting" |
| `/meet` (with spaces) | "New Meeting" |
| `/meet standup` | "standup" |
| `/meet weekly sync` | "weekly sync" |

## Dependencies

- REQ-001: Create Google Meet Link
- REQ-002: Post Link to Channel

## Implementation

See `app/services/meeting_creator.rb` and `app/services/meet_command_handler.rb`.
