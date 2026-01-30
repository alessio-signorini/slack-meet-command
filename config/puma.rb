# Puma configuration
workers Integer(ENV.fetch('WEB_CONCURRENCY', 1))
threads_count = Integer(ENV.fetch('MAX_THREADS', 5))
threads threads_count, threads_count

preload_app!

port ENV.fetch('PORT', 8080)
environment ENV.fetch('RACK_ENV', 'development')

on_worker_boot do
  # Database connection handled per-request in models
end
