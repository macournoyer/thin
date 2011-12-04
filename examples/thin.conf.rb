# Event backend options
worker_connections 1024
# Disable epoll or kqueue will fallback to select.
# use_epoll false
# use_kqueue false

# Worker options
# worker_processes 0 # runs in a single process w/ limited features
worker_processes 4
timeout 30 # seconds

# Logging
log_path "./thin.log"
pid_path "./thin.pid"

# Listeners
listen 3000, :backlog => 128, :tcp_no_delay => true
listen "*:8080", :protocol => :http
listen "0.0.0.0:8081"

# Callbacks
before_fork do |server|
  puts "Preparing to fork a new worker ..."
end

after_fork do |server|
  puts "Worker forked!"
end