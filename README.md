# Slack /meet Command

A Ruby/Sinatra application that creates Google Meet links via Slack slash commands.

## Quick Start

1. Copy `.env.example` to `.env` and fill in your credentials
2. Install dependencies: `bundle install`
3. Run migrations: `bundle exec rake db:migrate`
4. Start server: `bundle exec rackup -p 9292`
5. Run tests: `bundle exec rake test`

## Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [requirements/](requirements/) - Detailed requirements
- [test/README.md](test/README.md) - Testing guide

## Architecture

- **Web Framework**: Sinatra with Puma
- **Database**: SQLite with Sequel ORM
- **APIs**: Google Meet REST API, Slack API
- **Deployment**: Fly.io

## Development

```bash
# Run the app
bundle exec rackup -p 9292

# Run tests
bundle exec rake test

# Run linter
bundle exec rubocop
```
