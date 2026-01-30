# REQ-030: Signature Verification

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/slack/req_030_signature_verification_test.rb`

## Description

Verify all incoming Slack requests using HMAC signature.

## Algorithm

1. Extract `X-Slack-Request-Timestamp` header
2. Check timestamp is within 5 minutes of current time (prevent replay)
3. Construct signature base string: `v0:{timestamp}:{request_body}`
4. Compute HMAC-SHA256 using `SLACK_SIGNING_SECRET`
5. Compare with `X-Slack-Signature` header (constant-time comparison)

## Acceptance Criteria

- [ ] Invalid signature returns 403 Forbidden
- [ ] Expired timestamp (> 5 min old) returns 403 Forbidden
- [ ] Missing headers return 403 Forbidden
- [ ] All `/slack/*` endpoints verify signature
- [ ] Health endpoint does NOT require signature

## Security

- Constant-time comparison prevents timing attacks
- Timestamp check prevents replay attacks
- Applied to all Slack endpoints

## Dependencies

None

## Implementation

See `lib/slack_request_verifier.rb`.
