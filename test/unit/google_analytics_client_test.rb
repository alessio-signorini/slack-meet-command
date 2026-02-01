require_relative '../test_helper'
require_relative '../../lib/google_analytics_client'

class GoogleAnalyticsClientTest < Minitest::Test
  def setup
    @logger = Minitest::Mock.new
  end

  def test_disabled_when_no_credentials
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: nil,
      api_secret: nil,
      logger: @logger
    )
    
    # Should not make any HTTP requests when disabled
    client.track_meet_command_used(has_title: true, user_id: 'U123', team_id: 'T123')
    client.track_auth_completed(user_id: 'U123', team_id: 'T123')
    
    # No assertions needed - just ensuring no errors or HTTP calls
  end

  def test_disabled_when_empty_credentials
    client = SlackMeet::GoogleAnalyticsClient.new(
      measurement_id: '',
      api_secret: '',
      logger: @logger
    )
    
    # Should not make any HTTP requests when disabled
    client.track_meet_command_used(has_title: true, user_id: 'U123', team_id: 'T123')
    client.track_auth_completed(user_id: 'U123', team_id: 'T123')
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
