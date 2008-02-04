module Thin
  # The Thin HTTP server used to served request.
  # It listen for incoming request on a given port
  # and forward all request to +app+.
  #
  # Based on HTTP 1.1 protocol specs:
  # http://www.w3.org/Protocols/rfc2616/rfc2616.html
  class Server
    include Logging
    include Daemonizable
    
    # Address and port on which the server is listening for connections.
    attr_accessor :port, :host
    
    # UNIX domain socket on which the server is listening for connections.
    attr_accessor :socket
    
    # App called with the request that produces the response.
    attr_accessor :app
    
    # Maximum time for incoming data to arrive
    attr_accessor :timeout
    
    # Creates a new server bound to <tt>host:port</tt>
    # or to +socket+ that will pass request to +app+.
    # If +host_or_socket+ contains a <tt>/</tt> it is assumed
    # to be a UNIX domain socket filename.
    # If a block is passed, a <tt>Rack::Builder</tt> instance
    # will be passed to build the +app+.
    # 
    #   Server.new '0.0.0.0', 3000 do
    #     use Rack::CommonLogger
    #     use Rack::ShowExceptions
    #     map "/lobster" do
    #       use Rack::Lint
    #       run Rack::Lobster.new
    #     end
    #   end.start
    #
    def initialize(host_or_socket, port=3000, app=nil, &block)
      if host_or_socket.include?('/')
        @socket    = host_or_socket
      else      
        @host      = host_or_socket
        @port      = port.to_i
      end       
      @app         = app
      @timeout     = 60 # sec
      @connections = []
      
      @app = Rack::Builder.new(&block).to_app if block
    end
    
    def self.start(*args, &block)
      new(*args, &block).start!
    end
    
    # Start the server and listen for connections
    def start
      raise ArgumentError, 'app required' unless @app
      
      trap('INT')  { stop }
      trap('TERM') { stop! }
      
      at_exit { remove_socket_file } if @socket
            
      # See http://rubyeventmachine.com/pub/rdoc/files/EPOLL.html
      EventMachine.epoll
      
      log   ">> Thin web server (v#{VERSION::STRING} codename #{VERSION::CODENAME})"
      trace ">> Tracing ON"
      
      EventMachine.run { @signature = start_server }
    end
    alias :start! :start
    
    # Stops the server after processing all current connections.
    # Calling twice is the equivalent of calling <tt>stop!</tt>.
    def stop
      return unless running?
      
      if @stopping
        stop!
      else
        @stopping = true
        
        # Do not accept anymore connection
        EventMachine.stop_server(@signature)
        
        unless wait_for_connections_and_stop
          # Still some connections running, schedule a check later
          EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
        end
      end
    end
    
    # Stops the server closing all current connections
    def stop!
      return unless running?
      
      log ">> Stopping ..."

      @connections.each { |connection| connection.close_connection }
      EventMachine.stop

      remove_socket_file
    end
    
    def connection_finished(connection)
      @connections.delete(connection)
    end
    
    def name
      if @socket
        "thin server (#{@socket})"
      else
        "thin server (#{@host}:#{@port})"
      end
    end
    alias :to_s :name
    
    def running?
      !@signature.nil?
    end
    
    protected
      def start_server
        if @socket
          start_server_on_socket
        else
          start_server_on_host
        end
      end
      
      def start_server_on_host
        log ">> Listening on #{@host}:#{@port}, CTRL+C to stop"
        EventMachine.start_server(@host, @port, Connection, &method(:initialize_connection))
      end
      
      def start_server_on_socket
        raise PlatformNotSupported, 'UNIX sockets not available on Windows' if Thin.win?
        
        log ">> Listening on #{@socket}, CTRL+C to stop"
        EventMachine.start_unix_domain_server(@socket, Connection, &method(:initialize_connection))
      end
      
      def initialize_connection(connection)
        connection.server                  = self
        connection.comm_inactivity_timeout = @timeout
        connection.app                     = @app
        connection.silent                  = @silent
        connection.unix_socket             = !@socket.nil?

        @connections << connection
      end
      
      def remove_socket_file
        File.delete(@socket) if @socket && File.exist?(@socket)
      end
      
      def wait_for_connections_and_stop
        if @connections.empty?
          stop!
          true
        else
          log ">> Waiting for #{@connections.size} connection(s) to finish, CTRL+C to force stop"
          false
        end
      end
  end
end