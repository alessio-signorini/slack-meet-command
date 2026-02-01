# Puma configuration
# Use single mode (workers = 0) in development, cluster mode in production
if ENV.fetch('RACK_ENV', 'development') == 'production'
  workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))
  preload_app!
else
  workers 0
end

threads_count = Integer(ENV.fetch('MAX_THREADS', 5))
threads threads_count, threads_count

# Bind to 0.0.0.0 on the specified port (default 8080)
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 8080)}"
environment ENV.fetch('RACK_ENV', 'development')
