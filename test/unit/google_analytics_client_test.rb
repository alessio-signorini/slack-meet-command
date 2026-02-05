require_relative '../test_helper'
require_relative '../../lib/google_analytics_client'
require 'stringio'

class GoogleAnalyticsClientTest < Minitest::Test
  def setup
    @log_output = StringIO.new
    @logger = Logger.new(@log_output)
    @logger.level = Logger::DEBUG
  end

  def test_disabled_when_no_credentials
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: nil,
      api_secret: nil,
      logger: @logger
    )
    
    # Check that initialization logs disabled state
    assert_match(/Google Analytics tracking disabled/, @log_output.string)
    
    @log_output.truncate(0)
    @log_output.rewind
    
    # Should not make any HTTP requests when disabled
    client.track_meet_command_used(has_title: true, user_id: 'U123', team_id: 'T123')
    client.track_auth_completed(user_id: 'U123', team_id: 'T123')
    
    # Should log that tracking was skipped
    assert_match(/GA tracking skipped - disabled/, @log_output.string)
  end

  def test_disabled_when_empty_credentials
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: '',
      api_secret: '',
      logger: @logger
    )
    
    # Check that initialization logs disabled state
    assert_match(/Google Analytics tracking disabled/, @log_output.string)
    
    # Should not make any HTTP requests when disabled
    client.track_meet_command_used(has_title: true, user_id: 'U123', team_id: 'T123')
    client.track_auth_completed(user_id: 'U123', team_id: 'T123')
  end

  def test_enabled_when_credentials_provided
    SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: 'G-TEST123',
      api_secret: 'test_secret',
      logger: @logger
    )

    # Check that initialization logs enabled state
    assert_match(/Google Analytics tracking enabled/, @log_output.string)
    assert_match(/G-TEST123/, @log_output.string)
  end

  def test_track_meet_command_with_title
    skip 'Requires GA credentials' unless ENV['GA_MEASUREMENT_ID']
    
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: ENV['GA_MEASUREMENT_ID'],
      api_secret: ENV['GA_API_SECRET'],
      logger: @logger
    )
    
    # Should not raise error
    client.track_meet_command_used(has_title: true, user_id: 'U123', team_id: 'T123')
  end

  def test_track_meet_command_without_title
    skip 'Requires GA credentials' unless ENV['GA_MEASUREMENT_ID']
    
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: ENV['GA_MEASUREMENT_ID'],
      api_secret: ENV['GA_API_SECRET'],
      logger: @logger
    )
    
    # Should not raise error
    client.track_meet_command_used(has_title: false, user_id: 'U456', team_id: 'T123')
  end

  def test_track_auth_completed
    skip 'Requires GA credentials' unless ENV['GA_MEASUREMENT_ID']
    
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: ENV['GA_MEASUREMENT_ID'],
      api_secret: ENV['GA_API_SECRET'],
      logger: @logger
    )
    
    # Should not raise error
    client.track_auth_completed(user_id: 'U789', team_id: 'T456')
  end
end
