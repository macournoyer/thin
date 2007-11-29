require 'thin/cluster'
require 'yaml'

module Thin::Commands::Cluster
  class Base < Thin::Command
    def self.config_attributes
      [:address, :port, :environment, :log_file, :pid_file, :cwd, :servers, :user, :group]
    end
    
    attr_accessor *self.config_attributes
    attr_accessor :config, :trace
    
    protected
      def load_from_config
        return unless File.exist?(config)
        
        hash = File.open(config) { |file| YAML.load(file) }
        
        self.class.config_attributes.each do |attr|
          send "#{attr}=", hash[attr.to_s]
        end
      end
  end
end