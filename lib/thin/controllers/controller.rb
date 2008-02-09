require 'yaml'

module Thin
  module Controllers
    # Raised when a mandatory option is missing to run a command.
    class OptionRequired < RuntimeError
      def initialize(option)
        super("#{option} option required")
      end
    end
  
    # Controls a Thin server.
    # Allow to start, stop, restart and configure a single thin server.
    class Controller
      include Logging
    
      # Command line options passed to the thin script
      attr_accessor :options
    
      def initialize(options)
        @options = options
        
        if @options[:socket]
          @options.delete(:address)
          @options.delete(:port)
        end
      end
    
      def start
        server = case
        when @options.has_key?(:socket)
          Server.new(@options[:socket])
        when @options.has_key?(:swiftiply)
          Server.new(Connectors::SwiftiplyClient.new(@options[:address], @options[:port], @options[:swiftiply]))
        else
          Server.new(@options[:address], @options[:port])
        end

        server.pid_file = @options[:pid]
        server.log_file = @options[:log]
        server.timeout  = @options[:timeout]

        if @options[:daemonize]
          server.daemonize
          server.change_privilege @options[:user], @options[:group] if @options[:user] && @options[:group]
        end

        # If a Rack config file is specified we eval it inside a Rack::Builder block to create
        # a Rack adapter from it. DHH was hacker of the year a couple years ago so we default
        # to Rails adapter.
        if @options[:rackup]
          rackup_code = File.read(@options[:rackup])
          server.app  = eval("Rack::Builder.new {( #{rackup_code}\n )}.to_app", nil, @options[:rackup])
        else
          server.app = Rack::Adapter::Rails.new(@options.merge(:root => @options[:chdir]))
        end

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
end