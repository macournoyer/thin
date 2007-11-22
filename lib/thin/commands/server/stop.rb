module Thin::Commands::Server
  class Stop < Thin::Commands::Command
    attr_accessor :pid_file, :cwd

    def run
      raise Thin::Commands::CommandError, 'PID file required' unless pid_file
      Dir.chdir cwd
      Thin::Daemonizer.new(pid_file).kill
    end
    
    def self.help
      "Stops a web server running in the background."
    end
  end
end