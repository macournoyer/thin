require 'thin/cluster'

module Thin::Commands::Cluster
  class Stop < Thin::Commands::Command
    attr_accessor :address, :port, :environment, :log_file, :pid_file, :cwd, :servers, :config
    
    def run
      # TODO load_from_config
      
      Dir.chdir cwd
      
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