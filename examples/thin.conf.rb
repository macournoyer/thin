# Event backend options
worker_connections 1024
# Disabling epoll or kqueue will fallback to select.
# use_epoll false
# use_kqueue false

# Worker options
# worker_processes 0 # runs in a single process w/ limited features.
worker_processes 4
timeout 30 # seconds

# Preload the app (the .ru file) before forking to workers.
# Enable with copy-on-write garbage collection for better memory usage.
preload_app true

# Logging
log_path "./thin.log"
pid_path "./thin.pid"

# Listeners
listen 3000, :backlog => 1024, :tcp_no_delay => true
listen "0.0.0.0:8080"
listen "[::]:8081" # IPv6
listen "/tmp/thin.sock" # UNIX domain socket

# Callbacks
before_fork do |server|
  puts "Preparing to fork a new worker ..."
end

after_fork do |server|
  puts "Worker forked!"
end

# Thin middlewares - Enable and control the features of Thin.
#
# The following middlewares are Thin specific and need to be mounted at the
# very top of the middleware stack.

# Enable `async.callback` feature.
use Thin::Async do
  # Middlewares applied to async responses.
  # These middlewares will only run after the response has been produced by the app,
  # thus any middleware modifying the `env` will be ignored.
  use Thin::Chunked
end
# Legacy `throw :async` support.
# use Thin::CatchAsync

# For slow apps, you can enable the use of threads.
# If you're using this in Rails, make sure to call config.threadsafe!
# use Thin::Threaded, :pool_size => 20

# Or optionally enable threads only on some paths.
# map '/threaded' do
#   use Thin::Threaded
# end

# Stream response body. This degrades performance.
# WARNING: you must disable Rack::Lock (config.threadsafe! in Rails) for this to work.
# use Thin::Streamed

# Stream files. Use this if you're on Heroku.
use Thin::StreamFile

