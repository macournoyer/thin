require 'thin/cluster'

module Thin::Commands::Cluster
  class Restart < Thin::Commands::Command
    attr_accessor :address, :port, :environment, :log_file, :pid_file, :cwd, :servers, :config
    
    def run
      # TODO load_from_config
      
      Dir.chdir cwd
      
      cluster = Thin::Cluster.new(address, port, servers,
                                  # Let Rails handle his thing and ignore files
                                  Thin::RailsHandler.new('.', environment),
                                  # Serve static files
                                  Thin::DirHandler.new('public')
                                 )
      cluster.log_file = log_file
      cluster.pid_file = pid_file

      cluster.restart
    end

    def self.help
      "Restart servers."
    end
  end
end