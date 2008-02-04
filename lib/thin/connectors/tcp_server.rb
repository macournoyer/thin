module Thin
  module Connectors
    class TcpServer < Connector
      # Address and port on which the server is listening for connections.
      attr_accessor :port, :host
      
      def initialize(host, port)
        @host = host
        @port = port
        super
      end
      
      def connect
        @signature = EventMachine.start_server(@host, @port, Connection, &method(:initialize_connection))
      end
      
      def disconnect
        EventMachine.stop_server(@signature)
      end
      
      def running?
        !@signature.nil?
      end
      
      def to_s
        "#{@host}:#{@port}"
      end
    end
  end
end