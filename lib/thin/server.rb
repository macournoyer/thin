module Thin
  # The uterly famous Thin HTTP server.
  # It listen for incoming request through a given backend
  # and forward all request to +app+.
  #
  # == TCP server
  # Create a new TCP server on bound to <tt>host:port</tt> by specifiying +host+
  # and +port+ as the first 2 arguments.
  #
  #   Thin::Server.start('0.0.0.0', 3000, app)
  #
  # == UNIX domain server
  # Create a new UNIX domain socket bound to +socket+ file by specifiying a filename
  # as the first argument. Eg.: /tmp/thin.sock. If the first argument contains a <tt>/</tt>
  # it will be assumed to be a UNIX socket. 
  #
  #   Thin::Server.start('/tmp/thin.sock', nil, app)
  #
  # == Using a custom backend
  # You can implement your own way to connect the server to its client by creating your
  # own Backend class and pass it as the first argument.
  #
  #   backend = Thin::Backends::MyFancyBackend.new('galaxy://faraway:1345')
  #   Thin::Server.start(backend, nil, app)
  #
  # == Rack application (+app+)
  # All requests will be processed through +app+ that must be a valid Rack adapter.
  # A valid Rack adapter (application) must respond to <tt>call(env#Hash)</tt> and
  # return an array of <tt>[status, headers, body]</tt>.
  #
  # == Building an app in place
  # If a block is passed, a <tt>Rack::Builder</tt> instance
  # will be passed to build the +app+. So you can do cool stuff like this:
  # 
  #   Thin::Server.start('0.0.0.0', 3000) do
  #     use Rack::CommonLogger
  #     use Rack::ShowExceptions
  #     map "/lobster" do
  #       use Rack::Lint
  #       run Rack::Lobster.new
  #     end
  #   end
  #
  class Server
    include Logging
    include Daemonizable
    extend  Forwardable
    
    # Default values
    DEFAULT_TIMEOUT                        = 30 #sec
    DEFAULT_PORT                           = 3000
    DEFAULT_MAXIMUM_CONNECTIONS            = 1024
    DEFAULT_MAXIMUM_PERSISTENT_CONNECTIONS = 512
        
    # Application (Rack adapter) called with the request that produces the response.
    attr_accessor :app
    
    # Backend handling the connections to the clients.
    attr_accessor :backend
    
    # Maximum number of seconds for incoming data to arrive before the connection
    # is dropped.
    def_delegators :@backend, :timeout, :timeout=
    
    # Maximum number of file or socket descriptors that the server may open.
    def_delegators :@backend, :maximum_connections, :maximum_connections=
    
    # Maximum number of connection that can be persistent at the same time.
    # Most browser never close the connection so most of the time they are closed
    # when the timeout occur. If we don't control the number of persistent connection,
    # if would be very easy to overflow the server for a DoS attack.
    def_delegators :@backend, :maximum_persistent_connections, :maximum_persistent_connections=
    
    # Address and port on which the server is listening for connections.
    def_delegators :@backend, :host, :port
    
    # UNIX domain socket on which the server is listening for connections.
    def_delegator :@backend, :socket
    
    def initialize(host_or_socket_or_backend, port=DEFAULT_PORT, app=nil, &block)
      # Try to intelligently select which backend to use.
      @backend = case
      when host_or_socket_or_backend.is_a?(Backends::Base)
        host_or_socket_or_backend
      when host_or_socket_or_backend.include?('/')
        Backends::UnixServer.new(host_or_socket_or_backend)
      else
        Backends::TcpServer.new(host_or_socket_or_backend, port.to_i)
      end

      @app            = app
      @backend.server = self
      
      # Set defaults
      @backend.maximum_connections            = DEFAULT_MAXIMUM_CONNECTIONS
      @backend.maximum_persistent_connections = DEFAULT_MAXIMUM_PERSISTENT_CONNECTIONS
      @backend.timeout                        = DEFAULT_TIMEOUT
      
      # Allow using Rack builder as a block
      @app = Rack::Builder.new(&block).to_app if block
      
      # If in debug mode, wrap in logger adapter
      @app = Rack::CommonLogger.new(@app) if Logging.debug?
    end
    
    # Lil' shortcut to turn this:
    # 
    #   Server.new(...).start
    # 
    # into this:
    # 
    #   Server.start(...)
    # 
    def self.start(*args, &block)
      new(*args, &block).start!
    end
        
    # Start the server and listen for connections.
    # Also register signals:
    # * INT calls +stop+ to shutdown gracefully.
    # * TERM calls <tt>stop!</tt> to force shutdown.
    def start
      raise ArgumentError, 'app required' unless @app
      
      setup_signals
            
      log   ">> Thin web server (v#{VERSION::STRING} codename #{VERSION::CODENAME})"
      debug ">> Debugging ON"
      trace ">> Tracing ON"
      
      log ">> Maximum connections set to #{@backend.maximum_connections}"
      log ">> Listening on #{@backend}, CTRL+C to stop"
      
      @backend.start
    end
    alias :start! :start
    
    # == Gracefull shutdown
    # Stops the server after processing all current connections.
    # As soon as this method is called, the server stops accepting
    # new requests and wait for all current connections to finish.
    # Calling twice is the equivalent of calling <tt>stop!</tt>.
    def stop
      if running?
        @backend.stop
                
        unless wait_for_connections_and_stop
          # Still some connections running, schedule a check later
          log ">> Waiting for #{@backend.size} connection(s) to finish, can take up to #{timeout} sec, CTRL+C to stop now"
          EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
        end
      else
        stop!
      end
    end
    
    # == Force shutdown
    # Stops the server closing all current connections right away.
    # This doesn't wait for connection to finish their work and send data.
    # All current requests will be dropped.
    def stop!
      log ">> Stopping ..."

      @backend.stop!
    end
    
    # Configure the server.
    # The process might need to have superuser privilege to set configure
    # server with optimal options.
    def config
      @backend.config
    end
        
    def name
      "thin server (#{@backend})"
    end
    alias :to_s :name
    
    # Return +true+ if the server is running and ready to receive requests.
    # Note that the server might still be running and return +false+ when
    # shuting down and waiting for active connections to complete.
    def running?
      @backend.running?
    end
    
    protected            
      def wait_for_connections_and_stop
        if @backend.empty?
          stop!
          true
        else
          false
        end
      end
      
      def setup_signals
        trap('QUIT') { stop }  unless Thin.win?
        trap('INT')  { stop! }
        trap('TERM') { stop! }
      end      
  end
end