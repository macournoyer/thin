require "eventmachine"
require "socket"

require "thin/system"
require "thin/connection"
require "thin/backends/prefork"
require "thin/backends/single_process"

module Thin
  class Server
    # Application (Rack adapter) called with the request that produces the response.
    attr_accessor :app
    
    # A tag that will show in the process listing
    attr_accessor :tag
    
    # Address on which the server is listening for connections.
    attr_accessor :address
    alias :host :address
    alias :host= :address=
    
    # Port on which the server is listening for connections.
    attr_accessor :port
    
    attr_accessor :backlog
    
    attr_accessor :workers
    
    # Workers are killer if they don't checked in under `timeout` seconds.
    attr_accessor :timeout
    
    attr_accessor :pid_path
    
    attr_accessor :log_path
    
    attr_accessor :use_epoll
    
    # Maximum number of file or socket descriptors that the server may open.
    attr_accessor :maximum_connections
    
    # Backend handling the connections to the clients.
    attr_writer :backend
    
    def initialize(app, address="0.0.0.0", port=3000)
      @app = app
      @address = address
      @port = port
      @backlog = 1024
      @timeout = 30
      @pid_path = "./thin.pid"
      @log_path = nil
      @use_epoll = true
      @maximum_connections = 1024
      
      if System.supports_fork?
        # One worker per processor
        @workers = System.processor_count
      else
        @workers = 0
      end
    end
    
    def backend
      @backend ||= begin
        if prefork?
          Backends::Prefork.new(self)
        else
          Backends::SingleProcess.new(self)
        end
      end
    end
    
    def start(daemonize=false)
      # Configure EventMachine
      EM.epoll if @use_epoll
      @maximum_connections = EM.set_descriptor_table_size(@maximum_connections)
      puts "Maximum connections set to #{@maximum_connections} per worker"
      
      # Starts and configure the server socket.
      @socket = TCPServer.new(@address, @port)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      @socket.listen(@backlog)
      
      trap("EXIT") { stop }
      
      puts "Using #{@workers} worker(s) ..." if @workers > 0
      puts "Listening on #{@address}:#{@port}, CTRL+C to stop"
      
      backend.start(daemonize) do
        EM.attach_server(@socket, Connection) { |c| c.server = self }
        @started = true
      end
    rescue
      @socket.close if @socket
      raise
    end
    
    def started?
      @started
    end
    
    def stop
      if started?
        puts "Stopping ..."
        backend.stop
        @socket.close
        @socket = nil
        @started = false
      end
    end
    alias :shutdown :stop
    
    def prefork?
      @workers > 0
    end
    
    def to_s
      "Thin" + (@tag ? " [#{@tag}]" : "")
    end
  end
end