require "preforker"
require "eventmachine"
require "kgio"

require_relative "acceptor"
require_relative "connection"

module Thin
  class Server
    attr_accessor :app
    
    def initialize(app, address="0.0.0.0", port=3000)
      @app = app
      @address = address
      @port = port
    end
    
    def start(workers=3)
      socket = Kgio::TCPServer.new(@address, @port)
      socket.listen(50)

      # Preforker.new(:timeout => 5, :workers => workers, :app_name => "Thin") do |master|
      #   EM.run do
      #     EM.add_periodic_timer(4) do
      #       EM.stop_event_loop unless master.wants_me_alive?
      #     end
      #     
      #     EM.watch(socket, Acceptor) { |c| c.server = self }
      #   end
      # end.start
      
      3.times do
        fork do
          EM.run do
            EM.watch(socket, Acceptor) { |c| c.server = self }
          end
        end
      end
      
      Process.waitall
      
      # EM.run do
      #   EM.start_server(@address, @port, Connection) { |c| c.server = self }
      # end
    end
  end
end