FROM ruby:3.2-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    sqlite-dev \
    tzdata

WORKDIR /app

# Install gems to vendor/bundle for deployment mode
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path 'vendor/bundle' && \
    bundle config set --local without 'development test' && \
    bundle config set --local force_ruby_platform true && \
    bundle install --jobs=4 && \
    bundle clean --force

# Production stage
FROM ruby:3.2-alpine

# Install runtime dependencies only
RUN apk add --no-cache \
    sqlite-libs \
    tzdata && \
    addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

WORKDIR /app

# Copy Gemfile and lockfile first
COPY --chown=app:app Gemfile Gemfile.lock ./

# Copy installed gems from builder
COPY --from=builder --chown=app:app /app/vendor/bundle ./vendor/bundle

# Configure bundler to use vendor/bundle and force ruby platform
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path 'vendor/bundle' && \
    bundle config set --local without 'development test' && \
    bundle config set --local force_ruby_platform true

# Copy application code
COPY --chown=app:app . .

# Set user
USER app

EXPOSE 8080
CMD ["./startup.sh"]
