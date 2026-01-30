Sequel.migration do
  change do
    create_table(:user_tokens) do
      primary_key :id
      String :slack_user_id, size: 50, null: false, unique: true
      String :slack_team_id, size: 50, null: false
      Text :google_access_token, null: false
      Text :google_refresh_token
      DateTime :google_token_expiry
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      index :slack_user_id, name: :idx_user_tokens_slack_user_id
    end
  end
end
