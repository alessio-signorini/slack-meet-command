require_relative '../../test_helper'
require_relative '../../../lib/configuration'

class Req010DefaultConfigTest < Minitest::Test
  def setup
    # Clear environment variables
    %w[MEET_ACCESS_TYPE MEET_AUTO_TRANSCRIBE MEET_AUTO_RECORD MEET_SMART_NOTES MEET_MODERATION].each do |var|
      ENV.delete(var)
    end
  end

  def teardown
    # Clear environment variables after test
    %w[MEET_ACCESS_TYPE MEET_AUTO_TRANSCRIBE MEET_AUTO_RECORD MEET_SMART_NOTES MEET_MODERATION].each do |var|
      ENV.delete(var)
    end
  end

  def test_loads_valid_config_file
    config = SlackMeet::Configuration.load

    assert_equal 'TRUSTED', config.access_type
    assert_equal false, config.auto_transcribe
    assert_equal false, config.auto_record
    assert_equal false, config.smart_notes
    assert_equal 'OFF', config.moderation
  end

  def test_raises_on_missing_file
    # Temporarily move config.json
    project_root = File.expand_path('../../../..', __FILE__)
    config_path = File.join(project_root, 'config.json')
    backup_path = "#{config_path}.backup"
    
    # Remove backup if it exists from previous test
    File.delete(backup_path) if File.exist?(backup_path)
    
    # Move the file
    File.rename(config_path, backup_path)
    
    # Verify file is gone
    refute File.exist?(config_path), "Config file should not exist"

    error = assert_raises(SlackMeet::ConfigurationError) do
      SlackMeet::Configuration.load
    end

    assert_match(/not found/, error.message)
    assert_match(/create config.json/, error.message)
  ensure
    # Always restore the file
    if File.exist?(backup_path)
      File.delete(config_path) if File.exist?(config_path)
      File.rename(backup_path, config_path)
    end
  end

  def test_uses_defaults_for_missing_keys
    config_data = {}
    config = SlackMeet::Configuration.new(config_data)

    assert_equal 'TRUSTED', config.access_type
    assert_equal false, config.auto_transcribe
    assert_equal false, config.auto_record
    assert_equal false, config.smart_notes
    assert_equal 'OFF', config.moderation
  end

  def test_environment_variable_overrides_access_type
    ENV['MEET_ACCESS_TYPE'] = 'OPEN'
    config = SlackMeet::Configuration.load

    assert_equal 'OPEN', config.access_type
  end

  def test_environment_variable_overrides_auto_transcribe
    ENV['MEET_AUTO_TRANSCRIBE'] = 'true'
    config = SlackMeet::Configuration.load

    assert_equal true, config.auto_transcribe
  end

  def test_environment_variable_overrides_auto_record
    ENV['MEET_AUTO_RECORD'] = '1'
    config = SlackMeet::Configuration.load

    assert_equal true, config.auto_record
  end

  def test_environment_variable_overrides_smart_notes
    ENV['MEET_SMART_NOTES'] = 'yes'
    config = SlackMeet::Configuration.load

    assert_equal true, config.smart_notes
  end

  def test_environment_variable_overrides_moderation
    ENV['MEET_MODERATION'] = 'ON'
    config = SlackMeet::Configuration.load

    assert_equal 'ON', config.moderation
  end

  def test_raises_on_invalid_access_type
    error = assert_raises(SlackMeet::ConfigurationError) do
      SlackMeet::Configuration.new('access_type' => 'INVALID')
    end

    assert_match(/Invalid access_type/, error.message)
    assert_match(/OPEN, TRUSTED, RESTRICTED/, error.message)
  end

  def test_raises_on_invalid_moderation
    error = assert_raises(SlackMeet::ConfigurationError) do
      SlackMeet::Configuration.new('moderation' => 'INVALID')
    end

    assert_match(/Invalid moderation/, error.message)
    assert_match(/OFF, ON/, error.message)
  end
end
