require 'yaml'

module Thin
  # Raised when a mandatory option is missing to run a command.
  class OptionRequired < RuntimeError
    def initialize(option)
      super("#{option} option required")
    end
  end
  
  # Control a Thin server.
  # Allow to start, stop, restart and configure a single thin server.
  class Controller
    include Logging
    
    # Command line options passed to the thin script
    attr_accessor :options
    
    def initialize(options)
      @options = options
    end
    
    def start
      if @options[:socket]
        server = Server.new(@options[:socket])
      else
        server = Server.new(@options[:address], @options[:port])
      end

      server.pid_file = @options[:pid]
      server.log_file = @options[:log]
      server.timeout  = @options[:timeout]

      if @options[:daemonize]
        server.daemonize
        server.change_privilege @options[:user], @options[:group] if @options[:user] && @options[:group]
      end

      server.app = Rack::Adapter::Rails.new(@options.merge(:root => @options[:chdir]))

      # If a prefix is required, wrap in Rack URL mapper
      server.app = Rack::URLMap.new(@options[:prefix] => server.app) if @options[:prefix]

      # If a stats are required, wrap in Stats adapter
      server.app = Stats::Adapter.new(server.app, @options[:stats]) if @options[:stats]

      # Register restart procedure
      server.on_restart { Command.run(:start, @options) }

      server.start
    end
    
    def stop
      raise OptionRequired, :pid unless @options[:pid]
      
      Server.kill(@options[:pid], @options[:timeout] || 60)
    end
    
    def restart
      raise OptionRequired, :pid unless @options[:pid]
      
      Server.restart(@options[:pid])
    end
    
    def config
      config_file = @options.delete(:config) || raise(OptionRequired, :config)

      # Stringify keys
      @options.keys.each { |o| @options[o.to_s] = @options.delete(o) }

      File.open(config_file, 'w') { |f| f << @options.to_yaml }
      log ">> Wrote configuration to #{config_file}"
    end
  end
end