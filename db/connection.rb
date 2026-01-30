require 'sequel'

# Database connection setup
module SlackMeet
  class Database
    # Get the database connection
    #
    # @return [Sequel::Database] The database connection
    def self.connection
      @connection ||= establish_connection
    end

    # Establish database connection
    #
    # @return [Sequel::Database] The database connection
    def self.establish_connection
      db_url = ENV.fetch('DATABASE_URL', 'sqlite://db/development.sqlite3')
      
      # Create directory if it doesn't exist
      if db_url.start_with?('sqlite://')
        db_path = db_url.sub('sqlite://', '')
        db_dir = File.dirname(db_path)
        FileUtils.mkdir_p(db_dir) unless File.directory?(db_dir)
      end
      
      Sequel.connect(db_url)
    end

    # Reset connection (useful for testing)
    def self.reset!
      @connection&.disconnect
      @connection = nil
    end
  end
end
