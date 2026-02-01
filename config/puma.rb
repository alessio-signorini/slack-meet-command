# Puma configuration optimized for speed and memory
# Use single mode (workers = 0) in development, cluster mode in production
if ENV.fetch('RACK_ENV', 'development') == 'production'
  workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))
  preload_app!
  
  # Worker timeout - kill workers that take too long
  worker_timeout 60
  
  # Worker boot timeout
  worker_boot_timeout 30
  
  # Restart workers after N requests to prevent memory bloat
  worker_shutdown_timeout 30
  
  # Use fork to reduce memory per worker
  before_fork do
    require 'sequel'
    DB.disconnect if defined?(DB)
  end
  
  on_worker_boot do
    require_relative '../db/connection'
  end
else
  workers 0
end

# Reduce threads for lower memory usage and better performance
threads_count = Integer(ENV.fetch('MAX_THREADS', 3))
threads threads_count, threads_count

# Bind to 0.0.0.0 on the specified port (default 8080)
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 8080)}"
environment ENV.fetch('RACK_ENV', 'development')

# Disable stats endpoint to save memory
activate_control_app 'tcp://127.0.0.1:9293', { no_token: true } if ENV['PUMA_CONTROL_APP'] == 'true'

# Log config
quiet false
stdout_redirect nil, nil, false
