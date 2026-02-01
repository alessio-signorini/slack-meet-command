#!/bin/sh
set -e

# Ensure database directory exists and has proper permissions
DB_PATH="${DATABASE_URL:-sqlite:///data/production.sqlite3}"
DB_FILE=$(echo "$DB_PATH" | sed 's|sqlite://||')
DB_DIR=$(dirname "$DB_FILE")

# Check if directory is writable, if not exit with error
if [ ! -w "$DB_DIR" ]; then
  echo "ERROR: Database directory $DB_DIR is not writable by current user"
  echo "Current user: $(id)"
  echo "Directory permissions: $(ls -ld $DB_DIR)"
  exit 1
fi

echo "Running database migrations..."
bundle exec rake db:migrate

echo "Starting Puma server..."
exec bundle exec puma -C config/puma.rb
