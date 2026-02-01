require_relative '../../test_helper'
require_relative '../../../lib/slack_request_verifier'
require 'rack'
require 'openssl'
require 'stringio'

class Req030SignatureVerificationTest < Minitest::Test
  def setup
    @signing_secret = 'test_signing_secret'
    @timestamp = Time.now.to_i.to_s
    @body = 'token=test&team_id=T123&user_id=U123&command=/meet&text='
  end

  def test_valid_signature_passes
    request = build_request(@body, @timestamp, @signing_secret)
    
    # Should not raise
    SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @body, signing_secret: @signing_secret)
  end

  def test_invalid_signature_raises_error
    request = build_request(@body, @timestamp, 'wrong_secret')
    
    error = assert_raises(SlackMeet::Errors::SlackVerificationError) do
      SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @body, signing_secret: @signing_secret)
    end
    
    assert_match(/Invalid signature/, error.message)
  end

  def test_expired_timestamp_raises_error
    old_timestamp = (Time.now - (6 * 60)).to_i.to_s  # 6 minutes ago
    request = build_request(@body, old_timestamp, @signing_secret)
    
    error = assert_raises(SlackMeet::Errors::SlackVerificationError) do
      SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @body, signing_secret: @signing_secret)
    end
    
    assert_match(/too old/, error.message)
  end

  def test_future_timestamp_raises_error
    future_timestamp = (Time.now + (6 * 60)).to_i.to_s  # 6 minutes in future
    request = build_request(@body, future_timestamp, @signing_secret)
    
    error = assert_raises(SlackMeet::Errors::SlackVerificationError) do
      SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @body, signing_secret: @signing_secret)
    end
    
    assert_match(/too old/, error.message)
  end

  def test_missing_timestamp_header_raises_error
    env = {
      'HTTP_X_SLACK_SIGNATURE' => 'v0=signature',
      'rack.input' => StringIO.new(@body)
    }
    request = Rack::Request.new(env)
    
    error = assert_raises(SlackMeet::Errors::SlackVerificationError) do
      SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @body, signing_secret: @signing_secret)
    end
    
    assert_match(/Missing timestamp/, error.message)
  end

  def test_missing_signature_header_raises_error
    env = {
      'HTTP_X_SLACK_REQUEST_TIMESTAMP' => @timestamp,
      'rack.input' => StringIO.new(@body)
    }
    request = Rack::Request.new(env)
    
    error = assert_raises(SlackMeet::Errors::SlackVerificationError) do
      SlackMeet::SlackRequestVerifier.verify!(request, raw_body: @body, signing_secret: @signing_secret)
    end
    
    assert_match(/Missing signature/, error.message)
  end

  private

  def build_request(body, timestamp, signing_secret)
    sig_basestring = "v0:#{timestamp}:#{body}"
    signature = 'v0=' + OpenSSL::HMAC.hexdigest('SHA256', signing_secret, sig_basestring)
    
    env = {
      'HTTP_X_SLACK_REQUEST_TIMESTAMP' => timestamp,
      'HTTP_X_SLACK_SIGNATURE' => signature,
      'rack.input' => StringIO.new(body)
    }
    
    Rack::Request.new(env)
  end
end
