require_relative '../test_helper'
require_relative '../../lib/logger_factory'
require 'stringio'
require 'json'

class LoggerFactoryTest < Minitest::Test
  def setup
    @original_env = ENV['RACK_ENV']
    @original_log_level = ENV['LOG_LEVEL']
  end

  def teardown
    ENV['RACK_ENV'] = @original_env
    ENV['LOG_LEVEL'] = @original_log_level
  end

  def test_creates_logger_instance
    logger = SlackMeet::LoggerFactory.create

    assert_instance_of Logger, logger
  end

  def test_development_format_is_human_readable
    ENV['RACK_ENV'] = 'development'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.info('Test message')
    result = output.string

    assert_match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/, result)
    assert_match(/INFO/, result)
    assert_match(/Test message/, result)
  end

  def test_production_format_is_json
    ENV['RACK_ENV'] = 'production'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.info('Test message')
    result = output.string.strip

    parsed = JSON.parse(result)
    assert_equal 'INFO', parsed['level']
    assert_equal 'Test message', parsed['message']
    assert parsed['timestamp']
  end

  def test_development_includes_context_from_hash
    ENV['RACK_ENV'] = 'development'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.info(message: 'Meeting created', meeting_code: 'abc-defg-hij', user_id: 'U123')
    result = output.string

    assert_match(/Meeting created/, result)
    assert_match(/meeting_code=abc-defg-hij/, result)
    assert_match(/user_id=U123/, result)
  end

  def test_production_includes_context_from_hash
    ENV['RACK_ENV'] = 'production'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.info(message: 'Meeting created', meeting_code: 'abc-defg-hij', user_id: 'U123')
    result = output.string.strip

    parsed = JSON.parse(result)
    assert_equal 'INFO', parsed['level']
    assert_equal 'Meeting created', parsed['message']
    assert_equal 'abc-defg-hij', parsed['meeting_code']
    assert_equal 'U123', parsed['user_id']
  end

  def test_log_level_is_debug_in_development
    ENV['RACK_ENV'] = 'development'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.debug('Debug message')
    result = output.string

    assert_match(/Debug message/, result)
  end

  def test_log_level_is_info_in_production
    ENV['RACK_ENV'] = 'production'
    ENV['LOG_LEVEL'] = nil
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.debug('Debug message')
    result = output.string

    assert_equal '', result, 'DEBUG messages should not appear in production'
  end

  def test_log_level_override_with_env_variable
    ENV['RACK_ENV'] = 'production'
    ENV['LOG_LEVEL'] = 'DEBUG'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.debug('Debug message')
    result = output.string

    refute_equal '', result, 'DEBUG messages should appear when LOG_LEVEL=DEBUG'
  end

  def test_log_level_override_with_warn
    ENV['RACK_ENV'] = 'development'
    ENV['LOG_LEVEL'] = 'WARN'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.info('Info message')
    logger.warn('Warning message')
    result = output.string

    refute_match(/Info message/, result, 'INFO messages should not appear when LOG_LEVEL=WARN')
    assert_match(/Warning message/, result, 'WARN messages should appear when LOG_LEVEL=WARN')
  end

  def test_invalid_log_level_falls_back_to_info
    ENV['LOG_LEVEL'] = 'INVALID'
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.debug('Debug message')
    logger.info('Info message')
    result = output.string

    refute_match(/Debug message/, result, 'DEBUG should not appear with invalid LOG_LEVEL')
    assert_match(/Info message/, result, 'INFO should appear with fallback to INFO level')
  end
end
