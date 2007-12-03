module Thin::Commands::Cluster
  class Start < Base
    def run
      load_from_config
      
      cluster = Thin::Cluster.new(cwd, address, port, servers)

      cluster.environment = environment
      cluster.log_file    = log_file
      cluster.pid_file    = pid_file
      cluster.trace       = trace
      cluster.user        = user
      cluster.group       = group
      
      cluster.start
    end

    def self.help
      "Starts a bunch of servers"
    end
    
    def self.detailed_help
      <<-EOF
usage: thin_cluster start [options]

  Start multiple servers (--servers) starting on port --port.
  One pid file and log file will be created for each.
  
  By default 3 servers will be started:
  
  0.0.0.0:5000 pid-file=tmp/pids/thin.5000.pid log-file=log/thin.5000.log
  0.0.0.0:5001 pid-file=tmp/pids/thin.5001.pid log-file=log/thin.5001.log
  0.0.0.0:5002 pid-file=tmp/pids/thin.5002.pid log-file=log/thin.5002.log
  
  Use 'thin_cluster config' to create a config file and use
  it with the --config option.
EOF
    end
  end
end