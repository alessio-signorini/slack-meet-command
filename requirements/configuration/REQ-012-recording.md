# REQ-012: Auto-Recording Option

**Status**: Implemented  
**Priority**: Medium  
**Test File**: `test/requirements/configuration/req_012_recording_test.rb`

## Description

Configure whether meetings have auto-recording enabled.

## Acceptance Criteria

- [ ] When `auto_record: true`, sets `artifactConfig.recordingConfig.autoRecordingGeneration: "ON"`
- [ ] When `auto_record: false`, sets value to `"OFF"`
- [ ] Configuration can be set via `config.json`
- [ ] Configuration can be overridden via `MEET_AUTO_RECORD` environment variable
- [ ] Requires Google Workspace account

## API Mapping

```ruby
config = {
  artifactConfig: {
    recordingConfig: {
      autoRecordingGeneration: auto_record ? "ON" : "OFF"
    }
  }
}
```

## Dependencies

- REQ-010: Default Configuration

## Implementation

See `lib/configuration.rb` and `app/services/meeting_creator.rb`.
