module Thin
  class Configurator
    attr_reader :options

    def initialize(defaults={})
      @options = defaults.dup
      @options[:listeners] ||= []
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
      Listener.parse(address) # validates the address
      @options[:listeners] << [address, options]
    end

    # @see Thin::Server#timeout
    def timeout(seconds)
      set :timeout, seconds, Integer
    end

    # @see Thin::Server#log_path
    def log_path(path)
      set :log_path, path, String
    end

    def pid_path(path)
      set :pid_path, path, String
    end

    def use_epoll(value)
      set :use_epoll, value, TrueClass, FalseClass
    end

    def use_kqueue(value)
      set :use_kqueue, value, TrueClass, FalseClass
    end

    def before_fork(&block)
      @options[:before_fork] = block
    end

    def after_fork(&block)
      @options[:after_fork] = block
    end

    # Apply this configuration to the +server+ instance.
    # @param [Thin::Server] server
    def apply(server)
      [:worker_processes, :worker_connections, :timeout,
       :log_path, :pid_path,
       :use_epoll, :use_kqueue,
       :before_fork, :after_fork].each do |name|
        server.send "#{name}=", @options[name] if @options.has_key?(name)
      end
      @options[:listeners].each { |address, options| server.listen address, options }
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
