require "preforker"
require "eventmachine"
require "kgio"

require "thin/connection"
require "thin/system"

module Thin
  class Server
    attr_accessor :app
    
    def initialize(app, address="0.0.0.0", port=3000)
      @app = app
      @address = address
      @port = port
    end
    
    def start(workers=nil)
      socket = Kgio::TCPServer.new(@address, @port)
      socket.listen(50)

      trap("EXIT") { socket.close }
      
      if workers.nil?
        workers = System.processor_count
        puts "Detected #{workers} processors"
      end
      
      puts "Starting #{workers} workers ..."
      Preforker.new(:timeout => 5, :workers => workers, :app_name => "Thin") do |master|
        EM.run do
          EM.add_periodic_timer(4) do
            EM.stop_event_loop unless master.wants_me_alive?
          end
          
          EM.attach_server(socket, Connection) { |c| c.server = self }
        end
      end.start
    end
    
    def self.start(*args)
      new(*args).start
    end
  end
end