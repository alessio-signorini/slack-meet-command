require 'sinatra'
require 'json'

# Placeholder Sinatra app - will be implemented in Unit 13
get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now.utc.iso8601 }.to_json
end
