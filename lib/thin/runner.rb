require 'optparse'
require 'yaml'

module Thin
  # CLI runner.
  # Parse options and send command to the correct Controller.
  class Runner
    COMMANDS            = %w(start stop restart config)
    LINUX_ONLY_COMMANDS = %w(install)
    
    # Commands that wont load options from the config file
    CONFIGLESS_COMMANDS = %w(config install)
    
    # Parsed options
    attr_accessor :options
    
    # Name of the command to be runned.
    attr_accessor :command
    
    # Arguments to be passed to the command.
    attr_accessor :arguments
    
    # Return all available commands
    def self.commands
      commands  = COMMANDS
      commands += LINUX_ONLY_COMMANDS if Thin.linux?
      commands
    end
    
    def initialize(argv)
      @argv = argv
      
      # Default options values
      @options = {
        :chdir       => Dir.pwd,
        :environment => 'development',
        :address     => '0.0.0.0',
        :port        => 3000,
        :timeout     => 60,
        :log         => 'log/thin.log',
        :pid         => 'tmp/pids/thin.pid'
      }
      
      parse!
    end
    
    def parser
      # NOTE: If you add an option here make sure the key in the +options+ hash is the
      # same as the name of the command line option.
      # +option+ keys are used to build the command line to launch other processes,
      # see <tt>lib/thin/command.rb</tt>.
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: thin [options] #{self.class.commands.join('|')}"

        opts.separator ""
        opts.separator "Server options:"

        opts.on("-a", "--address HOST", "bind to HOST address " +
                                        "(default: #{@options[:address]})")             { |host| @options[:address] = host }
        opts.on("-p", "--port PORT", "use PORT (default: #{@options[:port]})")          { |port| @options[:port] = port.to_i }
        opts.on("-S", "--socket FILE", "bind to unix domain socket")                    { |file| @options[:socket] = file }
        opts.on("-y", "--swiftiply [KEY]", "Run using swiftiply")                       { |key| @options[:swiftiply] = key }
        opts.on("-e", "--environment ENV", "Rails environment " +                       
                                           "(default: #{@options[:environment]})")      { |env| @options[:environment] = env }
        opts.on("-c", "--chdir DIR", "Change to dir before starting")                   { |dir| @options[:chdir] = File.expand_path(dir) }
        opts.on("-t", "--timeout SEC", "Request or command timeout in sec " +            
                                       "(default: #{@options[:timeout]})")              { |sec| @options[:timeout] = sec.to_i }
        opts.on("-r", "--rackup FILE", "Load a Rack config file instead of " +
                                       "the Rails adapter")                             { |file| @options[:rackup] = file }
        opts.on(      "--prefix PATH", "Mount the app under PATH (start with /)")       { |path| @options[:prefix] = path }
        opts.on(      "--stats PATH", "Mount the Stats adapter under PATH")             { |path| @options[:stats] = path }
        
        unless Thin.win? # Daemonizing not supported on Windows
          opts.separator ""
          opts.separator "Daemon options:"
                                                                                      
          opts.on("-d", "--daemonize", "Run daemonized in the background")              { @options[:daemonize] = true }
          opts.on("-l", "--log FILE", "File to redirect output " +                      
                                      "(default: #{@options[:log]})")                   { |file| @options[:log] = file }
          opts.on("-P", "--pid FILE", "File to store PID " +                            
                                      "(default: #{@options[:pid]})")                   { |file| @options[:pid] = file }
          opts.on("-u", "--user NAME", "User to run daemon as (use with -g)")           { |user| @options[:user] = user }
          opts.on("-g", "--group NAME", "Group to run daemon as (use with -u)")         { |group| @options[:group] = group }
                                                                                      
          opts.separator ""
          opts.separator "Cluster options:"                                             
                                                                                      
          opts.on("-s", "--servers NUM", "Number of servers to start")                  { |num| @options[:servers] = num.to_i }
          opts.on("-o", "--only NUM", "Send command to only one server of the cluster") { |only| @options[:only] = only }
          opts.on("-C", "--config FILE", "Load options from config file")               { |file| @options[:config] = file }
          opts.on(      "--all [DIR]", "Send command to each config files in DIR")      { |dir| @options[:all] = dir } if Thin.linux?
        end
        
        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-D", "--debug", "Set debbuging on")       { $DEBUG = true }
        opts.on_tail("-V", "--trace", "Set tracing on")         { $TRACE = true }
        opts.on_tail("-h", "--help", "Show this message")       { puts opts; exit }
        opts.on_tail('-v', '--version', "Show version")         { puts Thin::SERVER; exit }
      end
    end
    
    # Parse the options.
    def parse!
      parser.parse! @argv
      @command   = @argv.shift
      @arguments = @argv
    end
        
    # Parse the current shell arguments and run the command.
    # Exits on error.
    def run!
      if self.class.commands.include?(@command)
        run_command
      elsif @command.nil?
        puts "Command required"
        puts @parser
        exit 1  
      else
        abort "Invalid command: #{@command}"
      end
    end
    
    # Send the command to the controller: single instance or cluster.
    def run_command
      load_options_from_config_file! unless CONFIGLESS_COMMANDS.include?(@command)
      
      # PROGRAM_NAME is relative to the current directory, so make sure
      # we store and expand it before changing directory.
      Command.script = File.expand_path($PROGRAM_NAME)
      
      # Change the current directory ASAP so that all relative paths are
      # relative to this one.
      Dir.chdir(@options[:chdir]) unless CONFIGLESS_COMMANDS.include?(@command)
      
      controller = case
      when cluster? then Controllers::Cluster.new(@options)
      when service? then Controllers::Service.new(@options)
      else               Controllers::Controller.new(@options)
      end
      
      if controller.respond_to?(@command)
        controller.send(@command, *@arguments)
      else
        abort "Invalid options for command: #{@command}"
      end
    end
    
    # +true+ if we're controlling a cluster.
    def cluster?
      @options[:only] || @options[:servers]
    end
    
    # +true+ if we're acting a as system service.
    def service?
      @options.has_key?(:all) || @command == 'install'
    end
    
    private
      def load_options_from_config_file!
        if file = @options.delete(:config)
          YAML.load_file(file).each { |key, value| @options[key.to_sym] = value }
        end
      end
  end
end