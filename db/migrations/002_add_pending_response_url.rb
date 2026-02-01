Sequel.migration do
  change do
    alter_table(:user_tokens) do
      add_column :pending_response_url, :text
    end
  end
end
