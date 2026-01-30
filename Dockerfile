FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

# Run migrations on startup
RUN bundle exec rake db:migrate

EXPOSE 8080
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
