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
      
      puts "Config file created : #{config}"
    end

    def self.help
      "Create a thin_cluster configuration file."
    end
    
    def self.detailed_help
      <<-EOF
usage: thin_cluster config [options]

  Create a configuration file for thin_cluster.
  
  All the options passed to this command will be stored
  in <config> in YAML format.
  
  You can then use this configuration file with the start,
  stop and restart commands with the --config option.
EOF
    end
  end
end