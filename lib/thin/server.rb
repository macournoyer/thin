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
    # Default: 0.0.0.0
    attr_accessor :address
    alias :host :address
    alias :host= :address=
    
    # Port on which the server is listening for connections.
    # Default: 9292
    attr_accessor :port
    
    # The maximum length of the queue of pending connections.
    # Default: 1024
    attr_accessor :backlog
    
    # Number of child worker processes.
    # Setting this to 0 will result in running in a single process with limited features.
    # Default: number of processors available or 0 if +fork+ is not available.
    attr_accessor :workers
    
    # Workers are killed if they don't check-in under +timeout+ seconds.
    # Default: 30
    attr_accessor :timeout
    
    # Path to the file in which the PID is saved.
    # Default: ./thin.pid
    attr_accessor :pid_path
    
    # Path to the file in which standard output streams are redirected.
    # Default: none, outputs to stdout
    attr_accessor :log_path
    
    # Set to +true+ to use epoll when available.
    # Default: true
    attr_accessor :use_epoll
    
    # Maximum number of file descriptors that the worker may open.
    # Default: 1024
    attr_accessor :worker_descriptor_table_size
    
    # Set the backend handling the connections to the clients.
    attr_writer :backend
    
    def initialize(app, address="0.0.0.0", port=9292)
      @app = app
      @address = address
      @port = port
      @backlog = 1024
      @timeout = 30
      @pid_path = "./thin.pid"
      @log_path = nil
      @use_epoll = true
      @worker_descriptor_table_size = 1024
      
      if System.supports_fork?
        # One worker per processor
        @workers = System.processor_count
      else
        # No workers, runs in a single process.
        @workers = 0
      end
    end
    
    # Backend handling connections to the clients.
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
      puts "Starting #{to_s} ..."
      
      # Configure EventMachine
      EM.epoll if @use_epoll
      @worker_descriptor_table_size = EM.set_descriptor_table_size(@worker_descriptor_table_size)
      puts "Maximum connections set to #{@worker_descriptor_table_size} per worker"
      
      # Starts and configure the server socket.
      @socket = TCPServer.new(@address, @port)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      @socket.listen(@backlog)
      
      trap("EXIT") { stop }
      
      puts "Using #{@workers} worker(s)" if @workers > 0
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