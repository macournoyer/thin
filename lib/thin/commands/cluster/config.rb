require 'thin/cluster'

module Thin::Commands::Cluster
  class Config < Thin::Commands::Command
    attr_accessor :address, :port, :environment, :log_file, :pid_file, :cwd, :servers, :config
    
    def run
      # TODO dump config
    end

    def self.help
      "Create a thin_cluster configuration file."
    end
  end
end