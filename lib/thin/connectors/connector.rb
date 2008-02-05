module Thin
  module Connectors
    class Connector
      include Logging
      
      # Server serving the connections throught the connector
      attr_reader :server
      
      # Maximum time for incoming data to arrive
      attr_accessor :timeout
      
      def initialize
        @connections = []
      end
      
      def server=(server)
        @server = server
        @silent = @server.silent
      end
      
      def close
      end
      
      def initialize_connection(connection)
        connection.connector               = self
        connection.app                     = @server.app
        connection.comm_inactivity_timeout = @timeout
        connection.silent                  = @silent

        @connections << connection
      end
      
      def connection_finished(connection)
        @connections.delete(connection)
      end
      
      def empty?
        @connections.empty?
      end
      
      def size
        @connections.size
      end
    end
  end
end