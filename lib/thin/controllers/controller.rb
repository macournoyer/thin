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
          Server.new(Backends::SwiftiplyClient.new(@options[:address], @options[:port], @options[:swiftiply]))
        else
          Server.new(@options[:address], @options[:port])
        end

        server.pid_file                       = @options[:pid]
        server.log_file                       = @options[:log]
        server.timeout                        = @options[:timeout]
        server.maximum_connections            = @options[:max_conns]
        server.maximum_persistent_connections = @options[:max_persistent_conns]

        server.daemonize if @options[:daemonize]

        server.config # Must be called before changing privileges since it might require superuser power.
        
        server.change_privilege @options[:user], @options[:group] if @options[:user] && @options[:group]

        # If a Rack config file is specified we eval it inside a Rack::Builder block to create
        # a Rack adapter from it. DHH was hacker of the year a couple years ago so we default
        # to Rails adapter.
        if @options[:rackup]
          rackup_code = File.read(@options[:rackup])
          server.app  = eval("Rack::Builder.new {( #{rackup_code}\n )}.to_app", TOPLEVEL_BINDING, @options[:rackup])
        else
          server.app = Rack::Adapter::Rails.new(@options.merge(:root => @options[:chdir]))
        end

        # If a prefix is required, wrap in Rack URL mapper
        server.app = Rack::URLMap.new(@options[:prefix] => server.app) if @options[:prefix]

        # If a stats URL is specified, wrap in Stats adapter
        server.app = Stats::Adapter.new(server.app, @options[:stats]) if @options[:stats]

        # Register restart procedure
        server.on_restart { Command.run(:start, @options) }

        server.start
      end
    
      def stop
        raise OptionRequired, :pid unless @options[:pid]
      
        tail_log(@options[:log]) do
          Server.kill(@options[:pid], @options[:timeout] || 60)
          wait_for_file :deletion, @options[:pid]
        end
      end
    
      def restart
        raise OptionRequired, :pid unless @options[:pid]
      
        tail_log(@options[:log]) do
          Server.restart(@options[:pid])
          wait_for_file :creation, @options[:pid]
        end
      end
    
      def config
        config_file = @options.delete(:config) || raise(OptionRequired, :config)

        # Stringify keys
        @options.keys.each { |o| @options[o.to_s] = @options.delete(o) }

        File.open(config_file, 'w') { |f| f << @options.to_yaml }
        log ">> Wrote configuration to #{config_file}"
      end
      
      protected
        # Wait for a pid file to either be created or deleted.
        def wait_for_file(state, file)
          case state
          when :creation then sleep 0.1 until File.exist?(file)
          when :deletion then sleep 0.1 while File.exist?(file)
          end
        end
        
        # Tail the log file of server +number+ during the execution of the block.        
        def tail_log(log_file)
          if log_file
            tail_thread = tail(log_file)
            yield
            tail_thread.kill
          else
            yield
          end
        end
        
        # Acts like GNU tail command. Taken from Rails.
        def tail(file)
          tail_thread = Thread.new do
            Thread.pass until File.exist?(file)
            cursor = File.size(file)
            last_checked = Time.now
            File.open(file, 'r') do |f|
              loop do
                f.seek cursor
                if f.mtime > last_checked
                  last_checked = f.mtime
                  contents = f.read
                  cursor += contents.length
                  print contents
                  STDOUT.flush
                end
                sleep 0.1
              end
            end
          end
          tail_thread
        end
    end
  end
end