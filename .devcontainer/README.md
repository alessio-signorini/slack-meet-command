# Devcontainer Setup

This devcontainer provides a complete Ruby development environment for the Slack /meet command application.

## What's Included

- **Ruby 3.2** - Latest stable Ruby version
- **Node.js** - For any JavaScript tooling needs
- **SQLite** - Development database
- **VS Code Extensions**:
  - Ruby LSP - Language server for Ruby
  - Ruby - Syntax highlighting and snippets
  - SQLite Viewer - Browse SQLite databases
  - REST Client - Test HTTP endpoints

## First-Time Setup

1. Open this folder in VS Code
2. When prompted, click "Reopen in Container"
3. Wait for the container to build (first time takes a few minutes)
4. The `postCreateCommand` will run `bundle install` automatically

## Running the Application

```bash
# Start the server
bundle exec puma -p 9292

# Or use rackup
bundle exec rackup -p 9292
```

The app will be available at http://localhost:9292

## Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/requirements/core/req_001_create_meet_link_test.rb

# Run with verbose output
bundle exec rake test TESTOPTS="--verbose"
```

## Database

```bash
# Run migrations
bundle exec rake db:migrate

# Reset database (development only)
rm -f db/development.sqlite3 && bundle exec rake db:migrate
```

## Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Required variables:
- `SLACK_SIGNING_SECRET` - From Slack app settings
- `GOOGLE_CLIENT_ID` - From Google Cloud Console
- `GOOGLE_CLIENT_SECRET` - From Google Cloud Console
- `APP_URL` - Your app's public URL (use ngrok for local dev)
- `SESSION_SECRET` - Generate with `ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"`

## Local Development with Slack

For local development, you need a public URL. Use ngrok:

```bash
# Install ngrok (outside container)
brew install ngrok

# Start tunnel (in another terminal, outside container)
ngrok http 9292
```

Then update your Slack app's Request URL with the ngrok URL.

## Troubleshooting

### Bundle install fails

If gems fail to install, try:

```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

### SQLite errors

Ensure the database directory exists:

```bash
mkdir -p db
bundle exec rake db:migrate
```

### Port already in use

Kill the process using the port:

```bash
lsof -i :9292 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

## Implementation Guide

See [specs.md](specs.md) for the complete implementation specification. The specification includes:

1. All requirements with acceptance criteria
2. 16 units of work to implement sequentially
3. Code quality standards and conventions
4. Testing strategy with mocked APIs
5. Deployment instructions

Follow the units of work in order, testing and committing after each one.
