require "optparse"
require "rack"

require "thin/configurator"

module Thin
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
          
          opts.on("-o", "--host HOST", "listen on HOST (default: 0.0.0.0)") { |host|
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
          
          opts.on("-W", "--workers NUMBER", "starts NUMBER of workers (default: number of processors)",
                                            "0 to run with limited features in a single process") { |n|
            options[:workers] = n.to_i
          }
          
          opts.on("-t", "--timeout SECONDS", "number of SECONDS before a worker times out (default: 30)") { |n|
            options[:timeout] = n.to_i
          }

          opts.on("-c", "--config FILE", "Thin configuration file") { |file|
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
        :host        => "0.0.0.0",
        :config      => "config.ru"
      }
    end
    
    def run(args)
      # Configure app
      options = default_options.dup
      
      parser = OptionsParser.new
      options.update parser.parse!(args)
      
      app, in_file_options = Rack::Builder.parse_file(options[:config], parser)
      options.update in_file_options
      
      ENV["RACK_ENV"] = options[:environment]
      options[:config] = ::File.expand_path(options[:config])
      
      app = build_app(app, options[:environment])
      
      # Start server
      server = Server.new(app, options[:host], options[:port])
      server.pid_path = options[:pid] if options[:pid]
      server.log_path = options[:log] if options[:log]
      server.workers = options[:workers] if options[:workers]
      server.timeout = options[:timeout] if options[:timeout]
      
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