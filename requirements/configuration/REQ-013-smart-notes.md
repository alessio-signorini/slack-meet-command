# REQ-013: Smart Notes Option

**Status**: Implemented  
**Priority**: Medium  
**Test File**: `test/requirements/configuration/req_013_smart_notes_test.rb`

## Description

Configure whether meetings have AI-generated smart notes enabled.

## Acceptance Criteria

- [ ] When `smart_notes: true`, sets `artifactConfig.smartNotesConfig.autoSmartNotesGeneration: "ON"`
- [ ] When `smart_notes: false`, sets value to `"OFF"`
- [ ] Configuration can be set via `config.json`
- [ ] Configuration can be overridden via `MEET_SMART_NOTES` environment variable
- [ ] Requires Google Workspace account

## API Mapping

```ruby
config = {
  artifactConfig: {
    smartNotesConfig: {
      autoSmartNotesGeneration: smart_notes ? "ON" : "OFF"
    }
  }
}
```

## Dependencies

- REQ-010: Default Configuration

## Implementation

See `lib/configuration.rb` and `app/services/meeting_creator.rb`.
