# REQ-031: Three-Second Response

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/slack/req_031_three_second_response_test.rb`

## Description

Respond to Slack within 3 seconds to avoid timeout.

## Acceptance Criteria

- [ ] Immediately return 200 OK with acknowledgment message
- [ ] Acknowledgment is ephemeral: `{ "response_type": "ephemeral", "text": "⏳ Creating meeting..." }`
- [ ] Actual work happens in background thread
- [ ] Result posted via `response_url` (async)

## Flow

1. Slack sends `/meet` command
2. App validates signature (< 100ms)
3. App returns immediate acknowledgment (< 200ms)
4. App spawns background thread
5. Background thread creates meeting, posts result

## Timing Requirements

- Signature verification: < 100ms
- Immediate response: < 200ms
- Total response time: < 3000ms (Slack timeout)

## Dependencies

- REQ-032: Async Callback

## Implementation

See `lib/async_job_runner.rb` and `app/services/meet_command_handler.rb`.
