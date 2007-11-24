module Thin::Commands::Cluster
  class Restart < Base
    def run
      load_from_config
      
      Dir.chdir cwd if cwd
      
      cluster = Thin::Cluster.new(address, port, servers,
                                  # Let Rails handle his thing and ignore files
                                  Thin::RailsHandler.new('.', environment),
                                  # Serve static files
                                  Thin::DirHandler.new('public')
                                 )
      cluster.log_file = log_file
      cluster.pid_file = pid_file
      cluster.user = user
      cluster.group = group

      cluster.restart
    end

    def self.help
      "Restart servers."
    end
  end
end