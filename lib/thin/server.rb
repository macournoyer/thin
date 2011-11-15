require "preforker"
require "eventmachine"

require "thin/connection"
require "thin/system"

module Thin
  class Server
    attr_accessor :app, :address, :port, :backlog, :worker_timeout, :pid_path, :log_path
    
    def initialize(app, address="0.0.0.0", port=3000)
      @app = app
      @address = address
      @port = port
      @backlog = 50
      @worker_timeout = 5
      @pid_path = "./thin.pid"
      @log_path = "./thin.log"
    end
    
    def start(workers=nil)
      socket = TCPServer.new(@address, @port)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      socket.listen(@backlog)

      trap("EXIT") { socket.close }
      
      if workers.nil?
        workers = System.processor_count
        puts "Detected #{workers} processor(s)"
      end
      
      puts "Starting #{workers} worker(s) ..."
      Preforker.new(:workers => workers,
                    :app_name => "Thin",
                    :timeout => @worker_timeout,
                    :pid_path => pid_path,
                    :logger => Logger.new(@log_path)) do |master|
        EM.run do
          EM.add_periodic_timer(4) do
            EM.stop_event_loop unless master.wants_me_alive?
          end
          
          EM.attach_server(socket, Connection) { |c| c.server = self }
        end
      end.run
    end
  end
end