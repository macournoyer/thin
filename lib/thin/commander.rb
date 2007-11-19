require 'optparse'
require 'ostruct'
require 'yaml'

module Thin
  class Commander
    attr_accessor :options, :commands
    
    def initialize(argv=nil)
      @options = OpenStruct.new(
        :address     => '0.0.0.0',
        :port        => 3000,
        :cwd         => nil,
        :environment => 'development',
        :daemonize   => false,
        :log_file    => nil,
        :pid_file    => 'tmp/pids/thin.pid',
        :servers     => 3
      )
      
      @commands = {}
      @include_options = [:cwd]
      @before = proc {}
      
      yield self if block_given?
      
      process! argv if argv
    end
    
    def process!(argv)
      parser.parse!(argv)
      error "Command required" if argv.size != 1
      command_name = argv.first.to_sym
      
      @before.call
      
      if @commands.has_key?(command_name)      
        @commands[command_name].call
      else
        error "Invalid command : #{command_name}"
      end
    end
    
    def parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROGRAM_NAME} [options] #{@commands.keys.join('|')}"
        
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-c", "--chdir PATH", "Change to dir before starting") do |cwd|
          options.cwd = cwd
        end

        opts.on("-p", "--port PORT", "Port number to bind to (default: 3000)") do |port|
          options.port = port.to_i
        end if include_option? :port

        opts.on("-a", "--address ADDR", "Address to bind to") do |address|
          options.address = address
        end if include_option? :address

        opts.on("-e", "--env ENV", "Rails environment (default: development)") do |environment|
          options.environment = environment
        end if include_option? :environment

        opts.on("-d", "--daemonize", "Run in the background") do
          options.daemonize = true
        end if include_option? :daemonize

        opts.on("-l", "--log FILE", "File to write log output to") do |log_file|
          options.log_file = log_file
        end if include_option? :log_file

        opts.on("-P", "--pid FILE", "File to write the PID (use with -d)") do |pid_file|
          options.pid_file = pid_file
        end if include_option? :pid_file

        opts.on("-n", "--number NUM", "Number of servers to launch") do |servers|
          options.servers = servers.to_i
        end if include_option? :servers

        opts.on("-C", "--config FILE", "Config file") do |config|
          options.config = config
        end if include_option? :config

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
          puts Thin::SERVER
          exit
        end
      end
    end
    
    def before(&block)
      @before = block
    end
    
    def on(command, &block)
      @commands[command.to_sym] = block
    end
    
    def error(message)
      STDERR.puts "Error: #{message}"
      exit 1
    end
    
    def include_options(*opts)
      @include_options += opts
    end
    
    def include_option?(opt)
      @include_options.include?(opt)
    end
    
    def to_yaml
      # Stringnify keys so we have a beautiful yaml dump (no : in front of keys)
      hash = options.marshal_dump.inject({}) do |h, (option, value)|
        h[option.to_s] = value if include_option?(option) && !%w(config)
        h
      end
      
      YAML.dump(hash)
    end
    
    def load_from_config
      error "Config file required" unless options.config
      
      hash = File.open(options.config) { |file| YAML.load(file) }
      hash = hash.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
      
      @options = OpenStruct.new(hash)
    end
    
    def dump_config
      error "Config file required" unless options.config
      File.open(options.config, "w") { |file| file << self.to_yaml }
    end
  end
end
