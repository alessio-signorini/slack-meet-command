# REQ-011: Auto-Transcription Option

**Status**: Implemented  
**Priority**: Medium  
**Test File**: `test/requirements/configuration/req_011_transcription_test.rb`

## Description

Configure whether meetings have auto-transcription enabled.

## Acceptance Criteria

- [ ] When `auto_transcribe: true`, sets `artifactConfig.transcriptionConfig.autoTranscriptionGeneration: "ON"`
- [ ] When `auto_transcribe: false`, sets value to `"OFF"`
- [ ] Configuration can be set via `config.json`
- [ ] Configuration can be overridden via `MEET_AUTO_TRANSCRIBE` environment variable
- [ ] Requires Google Workspace account (may silently fail for consumer accounts)

## API Mapping

```ruby
config = {
  artifactConfig: {
    transcriptionConfig: {
      autoTranscriptionGeneration: auto_transcribe ? "ON" : "OFF"
    }
  }
}
```

## Dependencies

- REQ-010: Default Configuration

## Implementation

See `lib/configuration.rb` and `app/services/meeting_creator.rb`.
