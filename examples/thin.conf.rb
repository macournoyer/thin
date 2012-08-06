# Event backend options
worker_connections 1024
# Disabling epoll or kqueue will fallback to select.
# use_epoll false
# use_kqueue false

# Threading
# For slow apps, you can enable the use of threads.
# If you're using this in Rails, make sure to call config.threadsafe!
threaded true # Call the app in a thread.
thread_pool_size 20

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

# Custom protocol
class Echo < EventMachine::Connection
  def receive_data(data)
    send_data data
    close_connection_after_writing
  end
end
listen 3001, :protocol => Echo

# Callbacks
before_fork do |server|
  puts "Preparing to fork a new worker ..."
end

after_fork do |server|
  puts "Worker forked!"
end
