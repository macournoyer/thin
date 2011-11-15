require "preforker"
require "eventmachine"
require "socket"

require "thin/connection"
require "thin/system"

module Thin
  class Server
    attr_accessor :app, :address, :port, :backlog, :timeout, :pid_path, :log_path, :use_epoll, :maximum_connections
    
    def initialize(app, address="0.0.0.0", port=3000)
      @app = app
      @address = address
      @port = port
      @backlog = 1024
      @timeout = 30
      @pid_path = "./thin.pid"
      @log_path = "./thin.log"
      @use_epoll = true
      @maximum_connections = 1024
    end
    
    def start(workers=nil)
      # Starts and configure the server socket.
      socket = TCPServer.new(@address, @port)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      socket.listen(@backlog)
      
      trap("EXIT") { socket.close }
      
      # One worker per processor
      workers = System.processor_count if workers.nil?
      
      # Configure EventMachine
      EM.epoll if @use_epoll
      @maximum_connections = EM.set_descriptor_table_size(@maximum_connections)
      puts "Maximum connections set to #{@maximum_connections} per worker"
      
      # Prefork!
      puts "Starting #{workers} worker(s) ..."
      prefork = Preforker.new(
                  :workers => workers,
                  :app_name => "Thin",
                  :timeout => @timeout,
                  :pid_path => pid_path,
                  :logger => Logger.new(@log_path)
                ) do |master|
        
        EM.run do
          EM.add_periodic_timer(4) do
            EM.stop_event_loop unless master.wants_me_alive?
          end
          
          EM.attach_server(socket, Connection) { |c| c.server = self }
        end
      end
      
      puts "Listening on #{@address}:#{@port}, CTRL+C to stop"
      prefork.run
    end
  end
end