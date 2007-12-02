module Thin::Commands::Cluster
  class Stop < Base
    def run
      load_from_config
      
      cluster = Thin::Cluster.new(cwd, address, port, servers)

      cluster.log_file = log_file
      cluster.pid_file = pid_file
      cluster.trace    = trace

      cluster.stop
    end

    def self.help
      "Stops all servers in the cluster."
    end
  end
end