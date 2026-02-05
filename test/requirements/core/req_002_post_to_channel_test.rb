require_relative '../../test_helper'
require_relative '../../../lib/slack_responder'
require_relative '../../../lib/logger_factory'

class Req002PostToChannelTest < Minitest::Test
  def setup
    @logger = SlackMeet::LoggerFactory.create(output: StringIO.new)
    @responder = SlackMeet::SlackResponder.new(logger: @logger)
  end

  def test_meeting_created_message_includes_meeting_name
    message = @responder.meeting_created_message(
      meeting_name: 'Standup',
      meeting_uri: 'https://meet.google.com/abc-defg-hij'
    )

    assert_equal 'in_channel', message[:response_type]
    assert message[:blocks]
    
    text_block = message[:blocks].find { |b| b[:type] == 'section' }
    assert_match(/Standup/, text_block[:text][:text])
  end

  def test_meeting_created_message_includes_meeting_uri
    meeting_uri = 'https://meet.google.com/abc-defg-hij'
    message = @responder.meeting_created_message(
      meeting_name: 'Test Meeting',
      meeting_uri: meeting_uri
    )

    text_block = message[:blocks].find { |b| b[:type] == 'section' }
    assert_match(/#{meeting_uri}/, text_block[:text][:text])
  end

  def test_meeting_created_message_replaces_original
    message = @responder.meeting_created_message(
      meeting_name: 'Test',
      meeting_uri: 'https://meet.google.com/abc-defg-hij'
    )

    assert_equal true, message[:replace_original]
  end

  def test_meeting_created_message_uses_in_channel_response_type
    message = @responder.meeting_created_message(
      meeting_name: 'Test',
      meeting_uri: 'https://meet.google.com/abc-defg-hij'
    )

    assert_equal 'in_channel', message[:response_type]
  end
end
