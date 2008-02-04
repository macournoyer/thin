module Thin
  module Connectors
    class Connector
      include Logging
      
      def initialize
        @connections = []
      end
      
      def close
      end
      
      def initialize_connection(connection)
        connection.connector               = self
        connection.comm_inactivity_timeout = @timeout
        connection.app                     = @app
        connection.silent                  = @silent
        connection.unix_socket             = !@socket.nil?

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