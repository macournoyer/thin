module Thin::Commands::Server
  class Stop < Base
    attr_accessor :pid_file, :timeout
    
    def cwd
      args.first || '.'
    end

    def run
      error 'PID file required' unless pid_file
      Dir.chdir cwd
      Thin::Server.kill(pid_file, timeout.to_i)
    end
    
    def self.help
      "Stops the web server running in the background."
    end

    def self.detailed_help
      <<-EOF
usage: thin stop [PATH] [options]

  Stops the web server running in the background
  which PID is in the file PATH/<pid-file>
  (default to <current directory>/tmp/pids/thin.pid).
EOF
    end
  end
end