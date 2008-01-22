module Thin
  # Raise when we require the server to stop
  class StopServer < Exception; end
  
  # The Thin HTTP server used to served request.
  # It listen for incoming request on a given port
  # and forward all request to +app+.
  #
  # Based on HTTP 1.1 protocol specs:
  # http://www.w3.org/Protocols/rfc2616/rfc2616.html
  class Server
    include Logging
    include Daemonizable
    
    # Addresse and port on which the server is listening for connections.
    attr_accessor :port, :host
    
    # App called with the request that produce the response.
    attr_accessor :app
    
    # Maximum time for incoming data to arrive
    attr_accessor :timeout
    
    # Creates a new server binded to <tt>host:port</tt>
    # that will pass request to +app+.
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
    #   end.start!
    #
    def initialize(host, port, app=nil, &block)
      @host       = host
      @port       = port.to_i
      @app        = app
      @timeout    = 60 # sec
      
      @app = Rack::Builder.new(&block).to_app if block
    end
    
    def self.start(host, port, &block)
      new(host, port, &block).start!
    end
    
    # Starts the handlers.
    def start
      raise ArgumentError, "app required" unless @app
      
      log   ">> Thin web server (v#{VERSION::STRING} codename #{VERSION::CODENAME})"
      trace ">> Tracing ON"
    end
    
    # Start the server and listen for connections
    def start!
      start
      listen!
    end
    
    # Start listening for connections
    def listen!
      trap('INT')  { stop }
      trap('TERM') { stop! }
      
      # See http://rubyeventmachine.com/pub/rdoc/files/EPOLL.html
      EventMachine.epoll
      
      EventMachine.run do
        begin
          log ">> Listening on #{@host}:#{@port}, CTRL+C to stop"
          EventMachine.start_server(@host, @port, Connection) do |connection|
            connection.comm_inactivity_timeout = @timeout
            connection.app                     = @app
            connection.silent                  = @silent
          end
        rescue StopServer
          EventMachine.stop_event_loop
        end
      end
    end
    
    def stop
      EventMachine.stop_event_loop
    rescue
      warn "Error stopping : #{$!}"
    end
    
    def stop!
      raise StopServer
    end
  end
end