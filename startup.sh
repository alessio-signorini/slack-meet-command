#!/bin/sh
set -e

echo "Running database migrations..."
bundle exec rake db:migrate

echo "Starting Puma server..."
exec bundle exec puma -C config/puma.rb
