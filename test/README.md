# Test Organization

This directory contains all tests for the Slack /meet command application.

## Test Categories

### Functional Tests (`requirements/`)

Test that requirements are met. Mirror the structure of `/requirements` directory.

- `core/` - Core functionality tests (REQ-001 to REQ-003)
- `configuration/` - Configuration tests (REQ-010 to REQ-015)
- `authentication/` - OAuth and token tests (REQ-020 to REQ-022)
- `slack/` - Slack integration tests (REQ-030 to REQ-032)
- `operations/` - Health and error handling tests (REQ-040 to REQ-041)

### Integration Tests (`integration/`)

Black-box endpoint tests that verify HTTP status, headers, and JSON schema.

### Support Files (`support/`)

- `api_mocks.rb` - WebMock helpers for Google and Slack APIs
- `factory_helpers.rb` - Test data builders

## Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/requirements/core/req_001_create_meet_link_test.rb

# Run with verbose output
bundle exec rake test TESTOPTS="--verbose"

# Run specific test method
bundle exec ruby test/requirements/core/req_001_create_meet_link_test.rb -n test_creates_google_meet_space_via_api
```

## Test Setup

All tests use:
- Minitest for test framework
- WebMock for HTTP mocking
- Rack::Test for integration tests

See `test_helper.rb` for common setup.

## Mocking Strategy

All external HTTP calls are mocked using WebMock:
- Google OAuth endpoints
- Google Meet API
- Slack response_url callbacks

See `support/api_mocks.rb` for mock helpers.
