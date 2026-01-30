# REQ-032: Async Callback

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/slack/req_032_async_callback_test.rb`

## Description

Post meeting result to Slack via `response_url`.

## Acceptance Criteria

- [ ] Use `response_url` from original request payload
- [ ] POST JSON with `Content-Type: application/json`
- [ ] Include `replace_original: true` to replace "Creating meeting..." message
- [ ] Handle HTTP errors gracefully (log, don't crash)
- [ ] `response_url` is valid for 30 minutes

## Response Format

```json
{
  "replace_original": true,
  "response_type": "in_channel",
  "blocks": [...]
}
```

## Error Handling

- Network errors: Log and continue
- HTTP errors (4xx, 5xx): Log and continue
- Timeout: Log and continue
- Never crash background thread

## Dependencies

- REQ-031: Three-Second Response

## Implementation

See `lib/slack_responder.rb`.
