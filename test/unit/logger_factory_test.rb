require_relative '../test_helper'
require_relative '../../lib/logger_factory'
require 'stringio'
require 'json'

class LoggerFactoryTest < Minitest::Test
  def setup
    @original_env = ENV['RACK_ENV']
  end

  def teardown
    ENV['RACK_ENV'] = @original_env
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
    output = StringIO.new
    logger = SlackMeet::LoggerFactory.create(output: output)

    logger.debug('Debug message')
    result = output.string

    assert_equal '', result, 'DEBUG messages should not appear in production'
  end
end
