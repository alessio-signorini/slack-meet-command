module SlackMeet
  module Errors
    # Base error class for all application errors
    class BaseError < StandardError; end

    # Raised when Slack request signature verification fails
    class SlackVerificationError < BaseError; end

    # Raised when user is not authenticated with Google
    class NotAuthenticatedError < BaseError; end

    # Raised when Google token refresh fails
    class TokenRefreshError < BaseError; end

    # Raised when Google API returns an error
    class GoogleApiError < BaseError
      attr_reader :status_code, :error_code

      def initialize(message, status_code: nil, error_code: nil)
        super(message)
        @status_code = status_code
        @error_code = error_code
      end
    end

    # Raised when configuration is invalid
    class ConfigurationError < BaseError; end
  end
end
