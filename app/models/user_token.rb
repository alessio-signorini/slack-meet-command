require 'sequel'
require_relative '../../db/connection'

module SlackMeet
  # Sequel model for user OAuth tokens
  class UserToken < Sequel::Model(SlackMeet::Database.connection[:user_tokens])
    plugin :timestamps, update_on_create: true
  end
end
