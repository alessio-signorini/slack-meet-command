# REQ-015: Moderation Option

**Status**: Implemented  
**Priority**: Low  
**Test File**: `test/requirements/configuration/req_015_moderation_test.rb`

## Description

Configure meeting moderation mode.

## Accepted Values

- `"OFF"`: Moderation disabled
- `"ON"`: Moderation enabled (host has more control)

## Acceptance Criteria

- [ ] Sets `config.moderation` on space creation
- [ ] Default is `"OFF"`
- [ ] Configuration can be set via `config.json`
- [ ] Configuration can be overridden via `MEET_MODERATION` environment variable

## API Mapping

```ruby
config = {
  config: {
    moderation: moderation  # "OFF" or "ON"
  }
}
```

## Dependencies

- REQ-010: Default Configuration

## Implementation

See `lib/configuration.rb` and `app/services/meeting_creator.rb`.
