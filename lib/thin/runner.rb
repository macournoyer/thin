require "rack"

module Thin
  class Runner < Rack::Server
    class Options
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
            options[:debug] = true
          }
          opts.on("-w", "--warn", "turn warnings on for your script") {
            options[:warn] = true
          }

          opts.on("-I", "--include PATH",
                  "specify $LOAD_PATH (may be used more than once)") { |path|
            options[:include] = path.split(":")
          }

          opts.on("-r", "--require LIBRARY",
                  "require the library, before executing your script") { |library|
            options[:require] = library
          }

          opts.separator ""
          opts.separator "Thin options:"

          opts.on("-o", "--host HOST", "listen on HOST (default: 0.0.0.0)") { |host|
            options[:Host] = host
          }

          opts.on("-p", "--port PORT", "use PORT (default: 9292)") { |port|
            options[:Port] = port
          }
          
          opts.on("-w", "--workers WORKERS", "number of workers to start (default: number of processor)") { |workers|
            options[:workers] = workers.to_i
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

          opts.separator ""
          opts.separator "Common options:"

          opts.on_tail("-h", "-?", "--help", "Show this message") do
            puts opts
            exit
          end

          opts.on_tail("--version", "Show version") do
            puts Thin::VERSION::SERVER
            exit
          end
        end

        begin
          opt_parser.parse! args
        rescue OptionParser::InvalidOption => e
          warn e.message
          abort opt_parser.to_s
        end
        
        options[:server] = "thin"
        options[:config] = args.last if args.last
        options
      end
    end
    
    def opt_parser
      Options.new
    end
  end
end