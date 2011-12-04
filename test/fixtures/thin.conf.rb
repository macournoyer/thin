worker_processes 4

worker_connections 1024

listen 3000, :backlog => 128
listen "*:8080"
listen "0.0.0.0:8081"

before_fork do
  puts "Preparing to fork a new worker ..."
end

after_fork do
  puts "Worker forked!"
end