require 'net/http'
require 'json'
require 'uri'

module SlackMeet
  # Formats and posts messages to Slack.
  #
  # @example
  #   responder = SlackResponder.new(logger: logger)
  #   responder.post_to_response_url(
  #     response_url: "https://hooks.slack.com/...",
  #     payload: responder.meeting_created_message(
  #       meeting_name: "Standup",
  #       meeting_uri: "https://meet.google.com/abc-defg-hij"
  #     )
  #   )
  #
  class SlackResponder
    # @param logger [Logger] Logger instance
    def initialize(logger:)
      @logger = logger
    end

    # Returns immediate acknowledgment message
    #
    # @return [Hash] Ephemeral acknowledgment message
    def immediate_acknowledgment
      {
        response_type: 'ephemeral',
        text: '⏳ Creating meeting...'
      }
    end

    # Returns meeting created message with Block Kit formatting
    #
    # @param meeting_name [String] Name of the meeting
    # @param meeting_uri [String] Google Meet link
    # @return [Hash] Block Kit message
    def meeting_created_message(meeting_name:, meeting_uri:)
      # Only show title if it's not the default
      text = if meeting_name == 'New Meeting'
        ":google-meet: #{meeting_uri}"
      else
        ":google-meet: *#{meeting_name}* #{meeting_uri}"
      end
      
      {
        response_type: 'in_channel',
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: text
            }
          }
        ]
      }
    end

    # Returns authentication required message
    #
    # @param auth_url [String] OAuth authorization URL
    # @return [Hash] Ephemeral message with auth button
    def auth_required_message(auth_url:)
      {
        response_type: 'ephemeral',
        text: "🔐 Click below to authorize this app to create *Google Meet* links on your behalf.",
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: "🔐 Click below to authorize this app to create *Google Meet* links on your behalf."
            }
          },
          {
            type: 'actions',
            elements: [
              {
                type: 'button',
                text: {
                  type: 'plain_text',
                  text: 'Connect Google Account',
                  emoji: true
                },
                url: auth_url,
                style: 'primary'
              }
            ]
          }
        ]
      }
    end

    # Returns error message
    #
    # @param text [String] Error message text
    # @return [Hash] Ephemeral error message
    def error_message(text:)
      {
        response_type: 'ephemeral',
        text: text
      }
    end

    # Posts a message to Slack via response_url
    #
    # @param response_url [String] Slack response URL
    # @param payload [Hash] Message payload
    # @return [Boolean] True if successful
    def post_to_response_url(response_url:, payload:)
      uri = URI.parse(response_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
      request.body = JSON.generate(payload)

      response = http.request(request)

      if response.code.to_i >= 200 && response.code.to_i < 300
        @logger.info(message: 'Posted to Slack', response_url: response_url, status: response.code)
        true
      else
        @logger.error(message: 'Failed to post to Slack', response_url: response_url, status: response.code, body: response.body)
        false
      end
    rescue StandardError => e
      @logger.error(message: 'Error posting to Slack', error: e.message, response_url: response_url)
      false
    end
  end
end
