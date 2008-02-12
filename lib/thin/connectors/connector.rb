module Thin
  module Connectors
    # A Connector connect the server to the client. It handles:
    # * connection/disconnection to the server
    # * initialization of the connections
    # * manitoring of the active connections.
    class Connector      
      # Server serving the connections throught the connector
      attr_accessor :server
      
      # Maximum time for incoming data to arrive
      attr_accessor :timeout
      
      def initialize
        @connections = []
        @timeout     = Server::DEFAULT_TIMEOUT
      end
            
      # Free up resources used by the connector.
      def close
      end
      
      def running?
        @server.running?
      end
            
      # Initialize a new connection to a client.
      def initialize_connection(connection)
        connection.connector               = self
        connection.app                     = @server.app
        connection.comm_inactivity_timeout = @timeout

        @connections << connection
      end
      
      # Close all active connections.
      def close_connections
        @connections.each { |connection| connection.close_connection }
      end
      
      # Called by a connection when it's unbinded.
      def connection_finished(connection)
        @connections.delete(connection)
      end
      
      # Returns +true+ if no active connection.
      def empty?
        @connections.empty?
      end
      
      # Number of active connections.
      def size
        @connections.size
      end
    end
  end
end