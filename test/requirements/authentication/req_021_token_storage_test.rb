require_relative '../../test_helper'
require_relative '../../../db/connection'
require_relative '../../../app/models/user_token'
require_relative '../../../lib/token_store'

class Req021TokenStorageTest < Minitest::Test
  def setup
    # Use in-memory database for tests
    @original_db_url = ENV['DATABASE_URL']
    ENV['DATABASE_URL'] = 'sqlite:/'
    
    # Reset connection and run migrations
    SlackMeet::Database.reset!
    db = SlackMeet::Database.connection
    Sequel.extension :migration
    Sequel::Migrator.run(db, 'db/migrations')
    
    @store = SlackMeet::TokenStore.new
  end

  def teardown
    SlackMeet::Database.reset!
    ENV['DATABASE_URL'] = @original_db_url
  end

  def test_store_and_retrieve_tokens
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_abc',
      refresh_token: 'refresh_xyz',
      expires_at: Time.now + 3600
    )

    token = @store.find_by_slack_user('U123')

    assert token
    assert_equal 'U123', token.slack_user_id
    assert_equal 'T123', token.slack_team_id
    assert_equal 'access_abc', token.google_access_token
    assert_equal 'refresh_xyz', token.google_refresh_token
    assert token.google_token_expiry
  end

  def test_update_existing_tokens
    # Store initial tokens
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_old',
      refresh_token: 'refresh_old',
      expires_at: Time.now + 1800
    )

    # Update with new tokens
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_new',
      refresh_token: 'refresh_new',
      expires_at: Time.now + 3600
    )

    token = @store.find_by_slack_user('U123')

    assert_equal 'access_new', token.google_access_token
    assert_equal 'refresh_new', token.google_refresh_token
  end

  def test_update_access_token_only
    # Store initial tokens
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_old',
      refresh_token: 'refresh_token',
      expires_at: Time.now + 1800
    )

    # Update only access token
    new_expiry = Time.now + 3600
    @store.update_access_token(
      slack_user_id: 'U123',
      access_token: 'access_new',
      expires_at: new_expiry
    )

    token = @store.find_by_slack_user('U123')

    assert_equal 'access_new', token.google_access_token
    assert_equal 'refresh_token', token.google_refresh_token, 'Refresh token should not change'
  end

  def test_delete_tokens
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_abc',
      refresh_token: 'refresh_xyz',
      expires_at: Time.now + 3600
    )

    deleted = @store.delete_for_user('U123')

    assert_equal 1, deleted
    assert_nil @store.find_by_slack_user('U123')
  end

  def test_token_expiring_soon_returns_true_when_expiring
    # Token expiring in 3 minutes
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_abc',
      refresh_token: 'refresh_xyz',
      expires_at: Time.now + (3 * 60)
    )

    assert @store.token_expiring_soon?('U123')
  end

  def test_token_expiring_soon_returns_false_when_not_expiring
    # Token expiring in 10 minutes
    @store.store_tokens(
      slack_user_id: 'U123',
      slack_team_id: 'T123',
      access_token: 'access_abc',
      refresh_token: 'refresh_xyz',
      expires_at: Time.now + (10 * 60)
    )

    refute @store.token_expiring_soon?('U123')
  end

  def test_token_expiring_soon_returns_false_for_missing_user
    refute @store.token_expiring_soon?('U999')
  end

  def test_find_by_slack_user_returns_nil_for_missing_user
    assert_nil @store.find_by_slack_user('U999')
  end
end
