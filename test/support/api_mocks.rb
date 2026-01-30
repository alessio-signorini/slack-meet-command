# Test helpers for mocking external API calls
module ApiMocks
  # Stub Slack response_url callback
  def stub_slack_response_url(response_url)
    stub_request(:post, response_url)
      .to_return(status: 200, body: 'ok')
  end
end
