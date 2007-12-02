module Thin::Commands::Cluster
  class Restart < Base
    def run
      load_from_config
      
      cluster = Thin::Cluster.new(cwd, address, port, servers)

      cluster.log_file = log_file
      cluster.pid_file = pid_file
      cluster.trace    = trace
      cluster.user     = user
      cluster.group    = group
      
      cluster.restart
    end

    def self.help
      "Restart servers."
    end
  end
end