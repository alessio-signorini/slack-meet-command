#!/bin/bash
set -e

echo "Installing Ruby dependencies..."
bundle install

echo "Running database migrations..."
bundle exec rake db:migrate

echo "Installing Fly CLI..."
curl -L https://fly.io/install.sh | sh -s -- --non-interactive --setup-path

echo "Configuring Fly CLI in PATH..."
echo 'export FLYCTL_INSTALL="/home/vscode/.fly"' >> ~/.bashrc
echo 'export PATH="$FLYCTL_INSTALL/bin:$PATH"' >> ~/.bashrc

echo "Setup complete!"
