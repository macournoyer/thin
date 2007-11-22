module Thin::Commands::Server
  class Start < Thin::Commands::Command
    attr_accessor :address, :port, :environment, :log_file, :daemonize, :pid_file, :cwd
    
    def run
      Dir.chdir cwd
      server = Thin::Server.new(address, port,
                                # Let Rails handle his thing and ignore files
                                Thin::RailsHandler.new('.', environment),
                                # Serve static files
                                Thin::DirHandler.new('public')
                               )
      server.logger = Logger.new(log_file) if log_file

      if daemonize
        Thin::Daemonizer.new(pid_file).daemonize { server.start }
      else
        server.start
      end
    end

    def self.help
      "Starts a new Thin web server for a Rails application."
    end
  end
end