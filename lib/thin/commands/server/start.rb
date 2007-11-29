module Thin::Commands::Server
  class Start < Base
    attr_accessor :address, :port, :environment, :log_file, :daemonize, :pid_file, :trace
    
    def run
      Dir.chdir cwd
      server = Thin::Server.new(address, port,
                                # Let Rails handle his thing and ignore files
                                Thin::RailsHandler.new('.', environment),
                                # Serve static files
                                Thin::DirHandler.new('public')
                               )
      server.logger = Logger.new(log_file) if log_file
      server.logger.level = trace ? Logger::DEBUG : Logger::INFO

      if daemonize
        Thin::Daemonizer.new(pid_file, log_file).daemonize { server.start }
      else
        server.start
      end
    end

    def self.help
      "Starts a new Thin web server for a Rails application."
    end

    def self.detailed_help
      <<-EOF
usage: thin start [PATH]

  Starts a new Thin web server for the Rails application in PATH
  (default to current directory).
EOF
    end      
  end
end