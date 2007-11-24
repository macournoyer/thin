module Thin::Commands::Cluster
  class Config < Base
    def run
      error 'Config file required' unless config
      
      Dir.chdir cwd if cwd
      
      hash = {}
      self.class.config_attributes.each do |attr|
        hash[attr.to_s] = send(attr)
      end
      
      File.open(config, 'w') { |f| f << YAML.dump(hash) }
    end

    def self.help
      "Create a thin_cluster configuration file."
    end
  end
end