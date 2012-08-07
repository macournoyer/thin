module Thin
  class Configurator
    attr_reader :options

    def initialize(defaults={}, &block)
      @options = defaults.dup
      @options[:listeners] ||= []
      
      instance_eval(&block) if block
    end

    # {include:Thin::Server#worker_processes}
    # @see Thin::Server#worker_processes
    def worker_processes(number)
      set :worker_processes, number, Integer
    end

    # {include:Thin::Server#worker_connections}
    # @see Thin::Server#worker_connections
    def worker_connections(number)
      set :worker_connections, number, Integer
    end

    # {include:Thin::Server#listen}
    # @see Thin::Server#listen
    def listen(address, options={})
      @options[:listeners] << Listener.new(address, options)
    end

    # {include:Thin::Server#preload_app}
    # @see Thin::Server#preload_app
    def preload_app(value)
      set :preload_app, value, TrueClass, FalseClass
    end

    # {include:Thin::Server#timeout}
    # @see Thin::Server#timeout
    def timeout(seconds)
      set :timeout, seconds, Integer
    end

    # {include:Thin::Server#timeout}
    # @see Thin::Server#timeout
    def keep_alive_requests(number)
      set :max_keep_alive_requests, number, Integer
    end

    # {include:Thin::Server#log_path}
    # @see Thin::Server#log_path
    def log_path(path)
      set :log_path, path, String
    end

    # {include:Thin::Server#pid_path}
    # @see Thin::Server#pid_path
    def pid_path(path)
      set :pid_path, path, String
    end

    # {include:Thin::Server#use_epoll}
    # @see Thin::Server#use_epoll
    def use_epoll(value)
      set :use_epoll, value, TrueClass, FalseClass
    end

    # {include:Thin::Server#use_kqueue}
    # @see Thin::Server#use_kqueue
    def use_kqueue(value)
      set :use_kqueue, value, TrueClass, FalseClass
    end

    # {include:Thin::Server#threaded}
    # @see Thin::Server#threaded
    def threaded(value)
      set :threaded, value, TrueClass, FalseClass
    end

    # {include:Thin::Server#thread_pool_size}
    # @see Thin::Server#thread_pool_size
    def thread_pool_size(value)
      set :thread_pool_size, value, Integer
    end

    # {include:Thin::Server#before_fork}
    # @see Thin::Server#before_fork
    def before_fork(&block)
      @options[:before_fork] = block
    end

    # {include:Thin::Server#after_fork}
    # @see Thin::Server#after_fork
    def after_fork(&block)
      @options[:after_fork] = block
    end

    # Apply this configuration to the +server+ instance.
    # @param [Thin::Server] server
    def apply(server)
      @options.each_pair { |name, value| server.send "#{name}=", value }
      server
    end

    # Read and eval a configuration file and returns the resulting Configurator instance.
    def self.load(file)
      config = new
      config.instance_eval(File.read(file), file)
      config
    end

    private
      def set(name, value, *classes)
        if classes.any? && classes.none? { |c| value.is_a?(c) }
          raise ArgumentError, "#{name}: #{value.inspect} is not of type " + classes.join(' or ')
        end
        @options[name] = value
      end
  end
end
