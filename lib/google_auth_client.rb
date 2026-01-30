require 'net/http'
require 'json'
require 'uri'
require_relative './errors'

module SlackMeet
  # Client for Google OAuth operations.
  #
  # @example
  #   client = GoogleAuthClient.new(
  #     client_id: ENV['GOOGLE_CLIENT_ID'],
  #     client_secret: ENV['GOOGLE_CLIENT_SECRET'],
  #     redirect_uri: "#{ENV['APP_URL']}/auth/google/callback"
  #   )
  #   url = client.authorization_url(state: 'encoded_state')
  #
  class GoogleAuthClient
    OAUTH_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth'.freeze
    TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token'.freeze
    SCOPE = 'https://www.googleapis.com/auth/meetings.space.created'.freeze

    attr_reader :client_id, :client_secret, :redirect_uri

    # Initialize the OAuth client
    #
    # @param client_id [String] Google OAuth client ID
    # @param client_secret [String] Google OAuth client secret
    # @param redirect_uri [String] OAuth redirect URI
    def initialize(client_id:, client_secret:, redirect_uri:)
      @client_id = client_id
      @client_secret = client_secret
      @redirect_uri = redirect_uri
    end

    # Generate OAuth authorization URL
    #
    # @param state [String] State parameter for CSRF protection
    # @return [String] Authorization URL
    def authorization_url(state:)
      params = {
        client_id: @client_id,
        redirect_uri: @redirect_uri,
        response_type: 'code',
        scope: SCOPE,
        access_type: 'offline',
        prompt: 'consent',
        state: state
      }

      "#{OAUTH_ENDPOINT}?#{URI.encode_www_form(params)}"
    end

    # Exchange authorization code for tokens
    #
    # @param code [String] Authorization code from OAuth callback
    # @param redirect_uri [String] Redirect URI (must match the one used for authorization)
    # @return [Hash] Token response with :access_token, :refresh_token, :expires_in
    # @raise [GoogleApiError] If token exchange fails
    def exchange_code(code:, redirect_uri:)
      params = {
        code: code,
        client_id: @client_id,
        client_secret: @client_secret,
        redirect_uri: redirect_uri,
        grant_type: 'authorization_code'
      }

      response = post_token_request(params)
      parse_token_response(response)
    end

    # Refresh an access token
    #
    # @param refresh_token [String] Refresh token
    # @return [Hash] Token response with :access_token, :expires_in
    # @raise [GoogleApiError] If token refresh fails
    # @raise [TokenRefreshError] If refresh token is invalid
    def refresh_access_token(refresh_token:)
      params = {
        refresh_token: refresh_token,
        client_id: @client_id,
        client_secret: @client_secret,
        grant_type: 'refresh_token'
      }

      response = post_token_request(params)
      
      if response.code.to_i == 400
        error_data = JSON.parse(response.body)
        if error_data['error'] == 'invalid_grant'
          raise Errors::TokenRefreshError, 'Refresh token is invalid or revoked'
        end
      end

      parse_token_response(response)
    rescue JSON::ParserError
      raise Errors::GoogleApiError.new('Invalid response from Google', status_code: response.code.to_i)
    end

    private

    def post_token_request(params)
      uri = URI.parse(TOKEN_ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data(params)

      http.request(request)
    end

    def parse_token_response(response)
      unless response.code.to_i == 200
        error_message = "Token request failed: #{response.code}"
        begin
          error_data = JSON.parse(response.body)
          error_message = "#{error_message} - #{error_data['error_description'] || error_data['error']}"
        rescue JSON::ParserError
          # Use default message
        end
        
        raise Errors::GoogleApiError.new(error_message, status_code: response.code.to_i)
      end

      data = JSON.parse(response.body)
      
      {
        access_token: data['access_token'],
        refresh_token: data['refresh_token'],
        expires_in: data['expires_in']
      }
    end
  end
end
