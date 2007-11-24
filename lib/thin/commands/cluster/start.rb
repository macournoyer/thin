module Thin::Commands::Cluster
  class Start < Base
    def run
      load_from_config
      
      Dir.chdir cwd
      
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
      
      cluster.start
    end

    def self.help
      "Starts a bunch of servers."
    end
  end
end