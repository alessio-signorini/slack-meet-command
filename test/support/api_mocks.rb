# Test helpers for mocking external API calls
module ApiMocks
  # Stub Slack response_url callback
  def stub_slack_response_url(response_url)
    stub_request(:post, response_url)
      .to_return(status: 200, body: 'ok')
  end

  # Stub Google Meet create space
  def stub_google_meet_create_space(meeting_uri: 'https://meet.google.com/abc-defg-hij', meeting_code: 'abc-defg-hij')
    stub_request(:post, 'https://meet.googleapis.com/v2/spaces')
      .to_return(
        status: 200,
        body: {
          name: 'spaces/abc123',
          meetingUri: meeting_uri,
          meetingCode: meeting_code
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub Google Meet API error
  def stub_google_meet_error(status: 500, error_message: 'Internal server error')
    stub_request(:post, 'https://meet.googleapis.com/v2/spaces')
      .to_return(
        status: status,
        body: {
          error: {
            code: status,
            message: error_message
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub Google OAuth token exchange
  def stub_google_token_exchange(access_token: 'ya29.access_token', refresh_token: '1//refresh_token', expires_in: 3600)
    stub_request(:post, 'https://oauth2.googleapis.com/token')
      .with(body: hash_including(grant_type: 'authorization_code'))
      .to_return(
        status: 200,
        body: {
          access_token: access_token,
          refresh_token: refresh_token,
          expires_in: expires_in,
          token_type: 'Bearer'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub Google OAuth token refresh
  def stub_google_token_refresh(access_token: 'ya29.new_access_token', expires_in: 3600)
    stub_request(:post, 'https://oauth2.googleapis.com/token')
      .with(body: hash_including(grant_type: 'refresh_token'))
      .to_return(
        status: 200,
        body: {
          access_token: access_token,
          expires_in: expires_in,
          token_type: 'Bearer'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub Google OAuth token refresh failure
  def stub_google_token_refresh_failure
    stub_request(:post, 'https://oauth2.googleapis.com/token')
      .with(body: hash_including(grant_type: 'refresh_token'))
      .to_return(
        status: 400,
        body: {
          error: 'invalid_grant',
          error_description: 'Token has been expired or revoked.'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
