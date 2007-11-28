module Thin
  # Wrapper around Server to manage several servers all at once.
  class Cluster
    attr_accessor :log_file, :pid_file, :user, :group
    
    # Create a new cluster of servers bound to +host+
    # on ports +first_port+ to <tt>first_port+size-1</tt>.
    def initialize(host, first_port, size, *handlers)
      @host = host
      @first_port = first_port
      @size = size
      @handlers = handlers
      
      @log_file = 'thin.log'
      @pid_file = 'thin.pid'
    end
    
    # Start the servers
    def start
      with_each_instance do |port|
        start_on_port port
      end
    end
    
    # Stop the servers
    def stop
      with_each_instance do |port|
        stop_on_port port
      end
    end
    
    # Restart the servers one at the time.
    # Prevent downtime by making sure only one is stopped at the time.
    # See http://blog.carlmercier.com/2007/09/07/a-better-approach-to-restarting-a-mongrel-cluster/
    def restart
      with_each_instance do |port|
        stop_on_port port
        start_on_port port
      end
    end
    
    def log_file_for(port)
      include_port_number @log_file, port
    end
    
    def pid_file_for(port)
      include_port_number @pid_file, port
    end
    
    private
      def start_on_port(port)        
        Daemonizer.new(pid_file_for(port), log_file_for(port)).daemonize("server on #{@host}:#{port}") do |daemon|
          server = Server.new(@host, port, *@handlers)

          FileUtils.mkdir_p File.dirname(log_file_for(port))
          server.logger   = Logger.new(log_file_for(port))
          
          if user
            server.logger.info "Changing process privileges to #{user}:#{group}"
            daemon.change_privilege(user, group || user)
          end
          server.start
        end
      end
    
      def stop_on_port(port)
        Daemonizer.new(pid_file_for(port), log_file_for(port)).kill
      end
    
      def with_each_instance
        @size.times do |n|
          port = @first_port + n
          yield port
        end
      end
      
      # Add the port numbers in the filename
      # so each instance get its own file
      def include_port_number(path, port)
        raise ArgumentError, "filename '#{path}' must include an extension" unless path =~ /\./
        path.gsub(/\.(.+)$/) { ".#{port}.#{$1}" }
      end
  end
end