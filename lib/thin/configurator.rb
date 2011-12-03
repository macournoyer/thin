module Thin
  class Configurator
    attr_reader :options
    
    def initialize(defaults={})
      @options = defaults.dup
      @options[:listeners] ||= []
    end
    
    def worker_processes(number)
      set :worker_processes, number, Integer
    end
    
    def worker_connections(number)
      set :worker_connections, number, Integer
    end
    
    def listen(address, options={})
      raise ArgumentError, "listen: #{address.inspect} is not a valid address" unless address.is_a?(String) || address.is_a?(Integer)
      @options[:listeners] << [address, options]
    end
    
    def timeout(seconds)
      set :timeout, seconds, Integer
    end
    
    def log_path(path)
      set :log_path, path, String
    end
    
    def pid_path(path)
      set :pid_path, path, String
    end
    
    def working_directory(path)
      set :working_directory, path, String
    end
    
    def use_epoll(value)
      set :use_epoll, value, TrueClass, FalseClass
    end
    
    def apply(server)
      # TODO: apply config to server object
    end
    
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