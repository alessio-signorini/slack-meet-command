# REQ-022: Token Refresh

**Status**: Implemented  
**Priority**: High  
**Test File**: `test/requirements/authentication/req_022_token_refresh_test.rb`

## Description

Automatically refresh expired access tokens.

## Acceptance Criteria

- [ ] Before API call, check if `google_token_expiry` is within 5 minutes
- [ ] If expiring soon, use refresh token to get new access token
- [ ] Update stored tokens with new access token and expiry
- [ ] If refresh fails (revoked), delete stored tokens and prompt re-auth
- [ ] Handle case where refresh token is missing (prompt re-auth)

## Refresh Logic

```ruby
if token_expiring_soon?(user_id)
  new_token = google_auth_client.refresh_access_token(refresh_token)
  update_access_token(user_id, new_token, expiry)
end
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Token expires < 5 min | Refresh automatically |
| Refresh succeeds | Update stored token, continue |
| Refresh fails (invalid_grant) | Delete tokens, prompt re-auth |
| No refresh token | Delete tokens, prompt re-auth |

## Dependencies

- REQ-020: Google OAuth Flow
- REQ-021: Token Storage

## Implementation

See `lib/token_store.rb` and `lib/google_auth_client.rb`.
