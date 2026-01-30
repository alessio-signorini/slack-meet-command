# REQ-014: Access Type Option

**Status**: Implemented  
**Priority**: High  
**Test File**: `test/requirements/configuration/req_014_access_type_test.rb`

## Description

Configure who can join meetings without knocking.

## Accepted Values

- `"OPEN"`: Anyone with link joins without knocking
- `"TRUSTED"`: Org members + invited externals join without knocking; others knock
- `"RESTRICTED"`: Only invitees join without knocking; everyone else knocks

## Acceptance Criteria

- [ ] Sets `config.accessType` on space creation
- [ ] Invalid values raise configuration error at startup
- [ ] Default is `"TRUSTED"`
- [ ] Configuration can be set via `config.json`
- [ ] Configuration can be overridden via `MEET_ACCESS_TYPE` environment variable

## API Mapping

```ruby
config = {
  config: {
    accessType: access_type  # "OPEN", "TRUSTED", or "RESTRICTED"
  }
}
```

## Dependencies

- REQ-010: Default Configuration

## Implementation

See `lib/configuration.rb` and `app/services/meeting_creator.rb`.
