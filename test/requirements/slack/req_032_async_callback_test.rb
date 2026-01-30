require_relative '../../test_helper'
require_relative '../../../lib/slack_responder'
require_relative '../../../lib/logger_factory'

class Req032AsyncCallbackTest < Minitest::Test
  def setup
    @logger = SlackMeet::LoggerFactory.create(output: StringIO.new)
    @responder = SlackMeet::SlackResponder.new(logger: @logger)
    @response_url = 'https://hooks.slack.com/commands/T123/456/abc'
  end

  def test_posts_to_response_url_with_json
    payload = @responder.meeting_created_message(
      meeting_name: 'Test',
      meeting_uri: 'https://meet.google.com/abc-defg-hij'
    )

    stub_slack_response_url(@response_url)

    result = @responder.post_to_response_url(
      response_url: @response_url,
      payload: payload
    )

    assert result, 'Should return true on success'
    
    # Verify the request was made
    assert_requested :post, @response_url,
                     headers: { 'Content-Type' => 'application/json' },
                     times: 1
  end

  def test_handles_http_errors_gracefully
    payload = @responder.error_message(text: 'Test error')

    stub_request(:post, @response_url).to_return(status: 500, body: 'Server error')

    result = @responder.post_to_response_url(
      response_url: @response_url,
      payload: payload
    )

    refute result, 'Should return false on error'
  end

  def test_handles_network_errors_gracefully
    payload = @responder.error_message(text: 'Test error')

    stub_request(:post, @response_url).to_timeout

    result = @responder.post_to_response_url(
      response_url: @response_url,
      payload: payload
    )

    refute result, 'Should return false on network error'
  end

  def test_immediate_acknowledgment_is_ephemeral
    message = @responder.immediate_acknowledgment

    assert_equal 'ephemeral', message[:response_type]
    assert_match(/Creating meeting/, message[:text])
  end

  def test_error_message_is_ephemeral
    message = @responder.error_message(text: 'Something went wrong')

    assert_equal 'ephemeral', message[:response_type]
    assert_equal 'Something went wrong', message[:text]
  end

  def test_auth_required_message_includes_button
    auth_url = 'https://example.com/auth/google'
    message = @responder.auth_required_message(auth_url: auth_url)

    assert_equal 'ephemeral', message[:response_type]
    
    actions_block = message[:blocks].find { |b| b[:type] == 'actions' }
    button = actions_block[:elements].first
    
    assert_equal 'button', button[:type]
    assert_equal auth_url, button[:url]
  end
end
