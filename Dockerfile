FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

EXPOSE 8080
CMD ["./startup.sh"]
