require_relative '../../test_helper'
require_relative '../../../lib/google_auth_client'

class Req020GoogleOauthTest < Minitest::Test
  def setup
    @client = SlackMeet::GoogleAuthClient.new(
      client_id: 'test_client_id.apps.googleusercontent.com',
      client_secret: 'test_client_secret',
      redirect_uri: 'http://localhost:9292/auth/google/callback'
    )
  end

  def test_authorization_url_includes_correct_scopes
    url = @client.authorization_url(state: 'test_state')

    assert_match(/scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fmeetings.space.created/, url)
  end

  def test_authorization_url_includes_offline_access
    url = @client.authorization_url(state: 'test_state')

    assert_match(/access_type=offline/, url)
  end

  def test_authorization_url_includes_consent_prompt
    url = @client.authorization_url(state: 'test_state')

    assert_match(/prompt=consent/, url)
  end

  def test_authorization_url_includes_state
    url = @client.authorization_url(state: 'encoded_user_data')

    assert_match(/state=encoded_user_data/, url)
  end

  def test_authorization_url_includes_client_id
    url = @client.authorization_url(state: 'test')

    assert_match(/client_id=test_client_id/, url)
  end

  def test_exchange_code_returns_tokens
    stub_google_token_exchange(
      access_token: 'ya29.test_access',
      refresh_token: '1//test_refresh',
      expires_in: 3600
    )

    result = @client.exchange_code(
      code: 'test_code',
      redirect_uri: @client.redirect_uri
    )

    assert_equal 'ya29.test_access', result[:access_token]
    assert_equal '1//test_refresh', result[:refresh_token]
    assert_equal 3600, result[:expires_in]
  end

  def test_exchange_code_raises_on_error
    stub_request(:post, 'https://oauth2.googleapis.com/token')
      .with(body: hash_including(grant_type: 'authorization_code'))
      .to_return(status: 400, body: '{"error": "invalid_grant"}')

    error = assert_raises(SlackMeet::Errors::GoogleApiError) do
      @client.exchange_code(code: 'bad_code', redirect_uri: @client.redirect_uri)
    end

    assert_match(/Token request failed/, error.message)
  end

  def test_refresh_access_token_returns_new_token
    stub_google_token_refresh(
      access_token: 'ya29.new_token',
      expires_in: 3600
    )

    result = @client.refresh_access_token(refresh_token: '1//test_refresh')

    assert_equal 'ya29.new_token', result[:access_token]
    assert_equal 3600, result[:expires_in]
  end

  def test_refresh_raises_token_refresh_error_on_invalid_grant
    stub_google_token_refresh_failure

    error = assert_raises(SlackMeet::Errors::TokenRefreshError) do
      @client.refresh_access_token(refresh_token: '1//bad_refresh')
    end

    assert_match(/invalid or revoked/, error.message)
  end
end
