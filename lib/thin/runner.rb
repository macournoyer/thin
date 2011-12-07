require "optparse"
require "rack"

require "thin/configurator"

module Thin
  # Command line runner. Mimic Rack's +rackup+.
  class Runner
    class OptionsParser
      def parse!(args)
        options = {}
        opt_parser = OptionParser.new("", 24, '  ') do |opts|
          opts.banner = "Usage: thin [ruby options] [thin options] [rackup config]"

          opts.separator ""
          opts.separator "Ruby options:"

          lineno = 1
          opts.on("-e", "--eval LINE", "evaluate a LINE of code") { |line|
            eval line, TOPLEVEL_BINDING, "-e", lineno
            lineno += 1
          }

          opts.on("-d", "--debug", "set debugging flags (set $DEBUG to true)") {
            $DEBUG = true
          }
          opts.on("-w", "--warn", "turn warnings on for your script") {
            $-w = true
          }

          opts.on("-I", "--include PATH",
                  "specify $LOAD_PATH (may be used more than once)") { |path|
            $LOAD_PATH.unshift *path.split(":")
          }

          opts.on("-r", "--require LIBRARY",
                  "require the library, before executing your script") { |library|
            require library
          }

          opts.separator ""
          opts.separator "Thin options:"

          opts.on("-o", "--host HOST", "bind to HOST") { |host|
            options[:host] = host
          }

          opts.on("-p", "--port PORT", "use PORT (default: 9292)") { |port|
            options[:port] = port
          }

          opts.on("-E", "--env ENVIRONMENT", "use ENVIRONMENT for defaults (default: development)") { |e|
            options[:environment] = e
          }

          opts.on("-D", "--daemonize", "run daemonized in the background") { |d|
            options[:daemonize] = d ? true : false
          }

          opts.on("-P", "--pid FILE", "file to store PID (default: thin.pid)") { |f|
            options[:pid] = ::File.expand_path(f)
          }

          opts.on("-l", "--log FILE", "file to log to (default: stdout)") { |f|
            options[:log] = ::File.expand_path(f)
          }

          opts.on("-c", "--config FILE", "Thin configuration file.") { |file|
            options[:thin_config] = file
          }

          opts.separator ""
          opts.separator "Common options:"

          opts.on_tail("-h", "-?", "--help", "Show this message") do
            puts opts
            exit
          end

          opts.on_tail("--version", "Show version") do
            puts Thin::SERVER
            exit
          end
        end

        begin
          opt_parser.parse! args
        rescue OptionParser::InvalidOption => e
          warn e.message
          abort opt_parser.to_s
        end

        options[:config] = args.last if args.last

        options
      end
    end

    def default_options
      {
        :environment => ENV['RACK_ENV'] || "development",
        :port        => 9292,
        :config      => "config.ru"
      }
    end

    def run(args)
      options = default_options.dup

      parser = OptionsParser.new
      options.update parser.parse!(args)

      # Build the Rack app
      app, in_file_options = Rack::Builder.parse_file(options[:config], parser)
      options.update in_file_options

      ENV["RACK_ENV"] = options[:environment]
      options[:config] = ::File.expand_path(options[:config])

      app = build_app(app, options[:environment])

      # Configure the server
      server = Server.new(app)

      if options[:thin_config]
        Configurator.load(options[:thin_config]).apply(server)
      end

      # If no listeners yet, use the one from the options
      if !options.has_key?(:thin_config) || server.listeners.empty?
        server.listen [options[:host], options[:port]].compact.join(":")
      end

      server.pid_path = options[:pid] if options[:pid]
      server.log_path = options[:log] if options[:log]
      server.worker_processes = options[:workers] if options[:workers]
      server.timeout = options[:timeout] if options[:timeout]

      # Start the server
      server.start(options[:daemonize])
    end

    def self.run(args)
      new.run(args)
    end

    private
      def build_app(inner_app, environment)
        Rack::Builder.new do
          case environment
          when "development"
            use Rack::ContentLength
            use Rack::Chunked
            use Rack::CommonLogger
            use Rack::ShowExceptions
            use Rack::Lint

          when "deployment"
            use Rack::ContentLength
            use Rack::Chunked
            use Rack::CommonLogger

          end

          run inner_app
        end
      end

  end
end
