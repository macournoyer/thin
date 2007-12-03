module Thin::Commands::Server
  class Start < Base
    attr_accessor :address, :port, :environment, :log_file, :daemonize, :pid_file, :user, :group, :trace, :timeout
    
    def run
      Dir.chdir cwd
      server = Thin::Server.new(address, port,
                                # Let Rails handle his thing and ignore files
                                Thin::RailsHandler.new('.', environment),
                                # Serve static files
                                Thin::DirHandler.new('public')
                               )

      server.log_file = log_file
      server.pid_file = pid_file
      server.trace    = trace
      server.timeout  = timeout.to_i

      server.change_privilege user, group || user if user
      server.start
      server.daemonize if daemonize
      server.listen!
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