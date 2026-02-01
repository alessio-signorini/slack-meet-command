require 'openssl'
require 'rack/utils'
require_relative './errors'

module SlackMeet
  # Verifies Slack request signatures to ensure requests are authentic.
  #
  # @example
  #   SlackRequestVerifier.verify!(request, signing_secret: ENV['SLACK_SIGNING_SECRET'])
  #
  class SlackRequestVerifier
    # Maximum age of a request in seconds (5 minutes)
    MAX_REQUEST_AGE = 5 * 60

    # Verify a Slack request signature
    #
    # @param request [Rack::Request] The request to verify
    # @param raw_body [String] The raw request body (must be provided before Sinatra parses it)
    # @param signing_secret [String] Slack signing secret
    # @raise [SlackVerificationError] If verification fails
    # @return [void]
    def self.verify!(request, raw_body:, signing_secret:)
      timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']
      signature = request.env['HTTP_X_SLACK_SIGNATURE']
      
      raise Errors::SlackVerificationError, 'Missing timestamp header' unless timestamp
      raise Errors::SlackVerificationError, 'Missing signature header' unless signature
      
      verify_timestamp!(timestamp)
      verify_signature!(raw_body, timestamp, signature, signing_secret)
    end

    # Verify the timestamp is within acceptable age
    #
    # @param timestamp [String] Request timestamp
    # @raise [SlackVerificationError] If timestamp is too old
    # @return [void]
    def self.verify_timestamp!(timestamp)
      request_time = Time.at(timestamp.to_i)
      age = Time.now - request_time
      
      if age.abs > MAX_REQUEST_AGE
        raise Errors::SlackVerificationError, 'Request timestamp too old'
      end
    end

    # Verify the HMAC signature
    #
    # @param body [String] Request body
    # @param timestamp [String] Request timestamp
    # @param signature [String] Slack signature
    # @param signing_secret [String] Slack signing secret
    # @raise [SlackVerificationError] If signature doesn't match
    # @return [void]
    def self.verify_signature!(body, timestamp, signature, signing_secret)
      sig_basestring = "v0:#{timestamp}:#{body}"
      computed_signature = 'v0=' + OpenSSL::HMAC.hexdigest('SHA256', signing_secret, sig_basestring)
      
      unless Rack::Utils.secure_compare(computed_signature, signature)
        raise Errors::SlackVerificationError, 'Invalid signature'
      end
    end
  end
end
