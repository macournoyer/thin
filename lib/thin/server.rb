module Thin
  # The uterly famous Thin HTTP server.
  # It listen for incoming request through a given connector
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
  # == Using a custom connector
  # You can implement your own way to connect the server to its client by creating your
  # own Thin::Connectors::Connector class and pass it as the first argument.
  #
  #   connector = Thin::Connectors::MyFancyConnector.new('galaxy://faraway:1345')
  #   Thin::Server.start(connector, nil, app)
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
    include Daemonizable unless Thin.win?
    extend  Forwardable
    
    # Default values
    DEFAULT_TIMEOUT = 30 #sec
    DEFAULT_PORT    = 3000
        
    # Application (Rack adapter) called with the request that produces the response.
    attr_accessor :app
    
    # Connector handling the connections to the clients.
    attr_accessor :connector
    
    # Sets the maximum number of file or socket descriptors that your process may open.
    attr_accessor :descriptor_table_size
    
    # Maximum number of seconds for incoming data to arrive before the connection
    # is dropped.
    def_delegators :@connector, :timeout, :timeout=
    
    # Address and port on which the server is listening for connections.
    def_delegators :@connector, :host, :port
    
    # UNIX domain socket on which the server is listening for connections.
    def_delegator :@connector, :socket
    
    def initialize(host_or_socket_or_connector, port=DEFAULT_PORT, app=nil, &block)
      # Try to intelligently select which connector to use.
      @connector = case
      when host_or_socket_or_connector.is_a?(Connectors::Connector)
        host_or_socket_or_connector
      when host_or_socket_or_connector.include?('/')
        Connectors::UnixServer.new(host_or_socket_or_connector)
      else
        Connectors::TcpServer.new(host_or_socket_or_connector, port.to_i)
      end

      @connector.server = self
      @app              = app
      
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
      
      trap('INT')  { stop }
      trap('TERM') { stop! }
            
      # See http://rubyeventmachine.com/pub/rdoc/files/EPOLL.html
      EventMachine.epoll
      
      log   ">> Thin web server (v#{VERSION::STRING} codename #{VERSION::CODENAME})"
      debug ">> Debugging ON"
      trace ">> Tracing ON"

      log ">> Setting descriptor table size to #{set_descriptor_table_size}"      
      log ">> Listening on #{@connector}, CTRL+C to stop"
      
      @running = true
      EventMachine.run { @connector.connect }
    end
    alias :start! :start
    
    # == Gracefull shutdown
    # Stops the server after processing all current connections.
    # As soon as this method is called, the server stops accepting
    # new requests and wait for all current connections to finish.
    # Calling twice is the equivalent of calling <tt>stop!</tt>.
    def stop
      if @running
        @running = false
        
        # Do not accept anymore connection
        @connector.disconnect
        
        unless wait_for_connections_and_stop
          # Still some connections running, schedule a check later
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

      @connector.close_connections
      EventMachine.stop

      @connector.close
    end
        
    def name
      "thin server (#{@connector})"
    end
    alias :to_s :name
    
    # Return +true+ if the server is running and ready to receive requests.
    # Note that the server might still be running and return +false+ when
    # shuting down and waiting for active connections to complete.
    def running?
      @running
    end
    
    protected            
      def wait_for_connections_and_stop
        if @connector.empty?
          stop!
          true
        else
          log ">> Waiting for #{@connector.size} connection(s) to finish, can take up to #{timeout} sec, CTRL+C to stop now"
          false
        end
      end
      
      def set_descriptor_table_size
        @descriptor_table_size = EventMachine.set_descriptor_table_size(@descriptor_table_size || 4096)
      end
  end
end