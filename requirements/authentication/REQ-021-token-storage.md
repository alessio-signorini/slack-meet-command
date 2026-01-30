# REQ-021: Token Storage

**Status**: Implemented  
**Priority**: Critical  
**Test File**: `test/requirements/authentication/req_021_token_storage_test.rb`

## Description

Persist OAuth tokens in SQLite database.

## Schema

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

## Acceptance Criteria

- [ ] Tokens stored with `slack_user_id` as unique key
- [ ] Both access and refresh tokens stored
- [ ] Token expiry timestamp stored for refresh logic
- [ ] Tokens can be updated (re-authorization)
- [ ] Tokens can be deleted (disconnect account)

## Token Store Interface

```ruby
TokenStore.find_by_slack_user(slack_user_id)
TokenStore.store_tokens(slack_user_id:, slack_team_id:, access_token:, refresh_token:, expires_at:)
TokenStore.update_access_token(slack_user_id:, access_token:, expires_at:)
TokenStore.delete_for_user(slack_user_id)
TokenStore.token_expiring_soon?(slack_user_id)
```

## Dependencies

None

## Implementation

See `db/migrations/001_create_user_tokens.rb`, `app/models/user_token.rb`, and `lib/token_store.rb`.
