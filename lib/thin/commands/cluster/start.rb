require 'thin/cluster'

module Thin::Commands::Cluster
  class Start < Thin::Commands::Command
    attr_accessor :address, :port, :environment, :log_file, :pid_file, :cwd, :servers, :config
    
    def run
      # TODO load_from_config
      
      Dir.chdir cwd
      
      cluster = Thin::Cluster.new(address, port, servers,
                                  # Let Rails handle his thing and ignore files
                                  Thin::RailsHandler.new('.', environment),
                                  # Serve static files
                                  Thin::DirHandler.new('public')
                                 )
      cluster.log_file = log_file
      cluster.pid_file = pid_file

      cluster.start
    end

    def self.help
      "Starts a bunch of servers."
    end
    
    # TODO
    # def to_yaml
    #   # Stringnify keys so we have a beautiful yaml dump (no : in front of keys)
    #   hash = options.marshal_dump.inject({}) do |h, (option, value)|
    #     h[option.to_s] = value if include_option?(option)
    #     h
    #   end
    #   hash.delete('config')
    #   
    #   YAML.dump(hash)
    # end
    # 
    # def load_from_config
    #   return unless File.exist?(options.config)
    #   
    #   hash = File.open(options.config) { |file| YAML.load(file) }
    #   hash = hash.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    #   
    #   @options = OpenStruct.new(hash)
    # end
  end
end