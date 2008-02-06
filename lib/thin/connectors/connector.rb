module Thin
  module Connectors
    # A Connector connect the server to the client. It handles:
    # * connection/disconnection to the server
    # * initialization of the connections
    # * manitoring of the active connections.
    class Connector
      include Logging
      
      # Server serving the connections throught the connector
      attr_reader :server
      
      # Maximum time for incoming data to arrive
      attr_accessor :timeout
      
      def initialize
        @connections = []
        @timeout     = 60 # sec
      end
            
      # Free up resources used by the connector.
      def close
      end
      
      def server=(server)
        @server = server
        @silent = @server.silent
      end
            
      # Initialize a new connection to a client.
      def initialize_connection(connection)
        connection.connector               = self
        connection.app                     = @server.app
        connection.comm_inactivity_timeout = @timeout
        connection.silent                  = @silent

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