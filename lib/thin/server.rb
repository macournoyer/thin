require "eventmachine"

require "thin/system"
require "thin/listener"
require "thin/backends/prefork"
require "thin/backends/single_process"

module Thin
  class Server
    # Application (Rack adapter) called with the request that produces the response.
    attr_accessor :app
    
    # A tag that will show in the process listing
    attr_accessor :tag
    
    # Number of child worker processes.
    # Setting this to 0 will result in running in a single process with limited features.
    # Default: number of processors available or 0 if +fork+ is not available.
    attr_accessor :worker_processes
    
    # Maximum number of file descriptors that the worker may open.
    # Default: 1024
    attr_accessor :worker_connections
    
    # Workers are killed if they don't check-in under +timeout+ seconds.
    # Default: 30
    attr_accessor :timeout
    
    # Path to the file in which the PID is saved.
    # Default: ./thin.pid
    attr_accessor :pid_path
    
    # Path to the file in which standard output streams are redirected.
    # Default: none, outputs to stdout
    attr_accessor :log_path
    
    # Set to +true+ to use epoll event model.
    attr_accessor :use_epoll
    
    # Set to +true+ to use kqueue event model.
    attr_accessor :use_kqueue
    
    # Set the backend handling the connections to the clients.
    attr_writer :backend
    
    attr_reader :listeners
    
    attr_accessor :before_fork
    
    attr_accessor :after_fork
    
    def initialize(app)
      @app = app
      @timeout = 30
      @pid_path = "./thin.pid"
      @log_path = nil
      @worker_connections = 1024
      
      if System.supports_fork?
        # One worker per processor
        @worker_processes = System.processor_count
      else
        # No workers, runs in a single process.
        @worker_processes = 0
      end
      
      @listeners = []
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
    
    def listen(address, options={})
      listener = Listener.parse(address)
      options = { :tcp_no_delay => true, :backlog => 1024, :protocol => :http }.merge(options)
      listener.protocol = options[:protocol]
      listener.tcp_no_delay = options[:tcp_no_delay]
      listener.listen(options[:backlog])
      @listeners << listener
    end
    
    def start(daemonize=false)
      puts "Starting #{to_s} ..."
      
      trap("EXIT") { stop }
      
      # Configure EventMachine
      EM.epoll = @use_epoll unless @use_epoll.nil?
      EM.kqueue = @use_kqueue unless @use_kqueue.nil?
      @worker_connections = EM.set_descriptor_table_size(@worker_connections)
      
      @listeners.each do |listener|
        puts "Listening on #{listener}"
      end
      puts "CTRL+C to stop"
      
      backend.start(daemonize) do
        @listeners.each do |listener|
          EM.attach_server(listener.socket, listener.protocol_class) { |c| c.server = self }
        end
        @started = true
      end
    rescue
      @listeners.each { |listener| listener.close }
      raise
    end
    
    def started?
      @started
    end
    
    def stop
      if started?
        puts "Stopping ..."
        backend.stop
        @listeners.each { |listener| listener.close }
        @started = false
      end
    end
    alias :shutdown :stop
    
    def prefork?
      @worker_processes > 0
    end
    
    def to_s
      "Thin" + (@tag ? " [#{@tag}]" : "")
    end
  end
end