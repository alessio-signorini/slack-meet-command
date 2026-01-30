# REQ-040: Health Endpoint

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/operations/req_040_health_endpoint_test.rb`

## Description

Provide health check endpoint for monitoring.

## Endpoint

`GET /health`

## Response

```json
{
  "status": "ok",
  "timestamp": "2026-01-29T12:00:00Z"
}
```

## Acceptance Criteria

- [ ] Returns 200 OK when app is healthy
- [ ] No authentication required
- [ ] Returns JSON with `status` and `timestamp`
- [ ] Used by Fly.io for health checks

## Health Check Logic

App is healthy if:
- Web server is responding
- No crashes in recent history

## Dependencies

None

## Implementation

See `app.rb`.
