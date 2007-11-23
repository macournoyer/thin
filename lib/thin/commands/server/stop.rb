module Thin::Commands::Server
  class Stop < Base
    attr_accessor :pid_file
    
    def cwd
      args.first || '.'
    end

    def run
      error 'PID file required' unless pid_file
      Dir.chdir cwd
      Thin::Daemonizer.new(pid_file).kill
    end
    
    def self.help
      "Stops the web server running in the background."
    end

    def self.detailed_help
      <<-EOF
usage: thin stop [PATH]

  Stops the web server running in the background
  which PID is in the file PATH/<pid-file>
  (default to <current directory>/tmp/pids/thin.pid).
EOF
    end
  end
end