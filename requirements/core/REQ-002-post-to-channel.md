# REQ-002: Post Link to Channel

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/core/req_002_post_to_channel_test.rb`

## Description

After creating the meeting, post the link back to the Slack channel or DM where the command was invoked.

## Acceptance Criteria

- [ ] Posts to Slack via `response_url` (async callback)
- [ ] Uses `response_type: "in_channel"` so all channel members see it
- [ ] Message includes meeting name (if provided) or "New Meeting"
- [ ] Message includes clickable meeting link
- [ ] Message includes "Join Meeting" button (Block Kit)
- [ ] Message format is visually clear and professional

## Block Kit Response Structure

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

## Dependencies

- REQ-032: Async Callback (for posting to response_url)

## Implementation

See `lib/slack_responder.rb`.
