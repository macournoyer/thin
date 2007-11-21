module Thin
  # Wrapper around Server to manage several servers all at once.
  class Cluster
    attr_accessor :log_file, :pid_file
    
    def initialize(host, first_port, size, *handlers)
      @host = host
      @first_port = first_port
      @size = size
      @handlers = handlers
      
      @log_file = 'thin.log'
      @pid_file = 'thin.pid'
    end
    
    def start
      with_each_instance do |port|
        start_on_port port
      end
    end
    
    def stop
      with_each_instance do |port|
        stop_on_port port
      end
    end
    
    # TODO
    def restart
      with_each_instance do |port|
        stop_on_port port
        # TODO wait for stopping to finish
        start_on_port port
      end
    end
    
    private
      def start_on_port(port)
        # Add the port numbers in the filename
        # so each instance get its own file
        log_file = include_port_number(@log_file, port)
        pid_file = include_port_number(@pid_file, port)
      
        server = Server.new(@host, port, *@handlers)
      
        FileUtils.mkdir_p File.dirname(log_file)
        server.logger   = Logger.new(log_file)
        
        server.pid_file = pid_file
      
        server.daemonize
      end
    
      def stop_on_port(port)
        pid_file = include_port_number(@pid_file, port)

        Server.kill pid_file
      end
    
      def with_each_instance
        @size.times do |n|
          port = @first_port + n
          yield port
        end
      end
      
      def include_port_number(path, port)
        raise ArgumentError, "filename '#{path}' must include an extension" unless path =~ /\./
        path.gsub(/\.(.+)$/) { ".#{port}.#{$1}" }
      end
  end
end