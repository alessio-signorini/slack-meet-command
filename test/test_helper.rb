ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'webmock/minitest'
require 'rack/test'

# Disable all real HTTP requests
WebMock.disable_net_connect!(allow_localhost: false)

# Load test support files
require_relative 'support/api_mocks'
require_relative 'support/factory_helpers'

# Include helpers in all tests
class Minitest::Test
  include ApiMocks
  include FactoryHelpers
end
