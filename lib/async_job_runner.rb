module SlackMeet
  # Executes jobs asynchronously in a background thread.
  #
  # @example
  #   AsyncJobRunner.perform_async(logger: logger) do
  #     # Long-running task
  #   end
  #
  class AsyncJobRunner
    # Execute a block asynchronously
    #
    # @param logger [Logger] Logger instance
    # @yield Block to execute asynchronously
    # @return [Thread] The spawned thread
    def self.perform_async(logger:, &block)
      Thread.new do
        begin
          block.call
        rescue StandardError => e
          logger.error(message: 'Error in async job', error: e.message, backtrace: e.backtrace.first(5))
        end
      end
    end
  end
end
