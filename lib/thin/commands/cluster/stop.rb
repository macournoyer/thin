module Thin::Commands::Cluster
  class Stop < Base
    def run
      load_from_config
      
      Dir.chdir cwd if cwd
      
      cluster = Thin::Cluster.new(address, port, servers)
      cluster.log_file = log_file
      cluster.pid_file = pid_file

      cluster.stop
    end

    def self.help
      "Stops all servers in the cluster."
    end
  end
end