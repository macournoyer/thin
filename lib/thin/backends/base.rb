module Thin
  module Backends
    # A Backend connects the server to the client. It handles:
    # * connection/disconnection to the server
    # * initialization of the connections
    # * manitoring of the active connections.
    class Base
      # Server serving the connections throught the backend
      attr_accessor :server
      
      # Maximum time for incoming data to arrive
      attr_accessor :timeout
      
      # Maximum number of file or socket descriptors that the server may open.
      attr_accessor :maximum_connections
      
      # Maximum number of connections that can be persistent
      attr_accessor :maximum_persistent_connections
      
      # Number of persistent connections currently opened
      attr_accessor :persistent_connection_count
      
      def initialize
        @connections                    = []
        @timeout                        = Server::DEFAULT_TIMEOUT
        @persistent_connection_count    = 0
        @maximum_connections            = Server::DEFAULT_MAXIMUM_CONNECTIONS
        @maximum_persistent_connections = Server::DEFAULT_MAXIMUM_PERSISTENT_CONNECTIONS
      end
      
      def start
        @stopping = false
        
        EventMachine.run do
          connect
          @running = true
        end
      end
      
      def stop
        @running  = false
        @stopping = true
        
        # Do not accept anymore connection
        disconnect
        stop! if @connections.empty?
      end
      
      def stop!
        @running  = false
        @stopping = false
        
        EventMachine.stop if EventMachine.reactor_running?
        @connections.each { |connection| connection.close_connection }
        close
      end
      
      def config
        # See http://rubyeventmachine.com/pub/rdoc/files/EPOLL.html
        EventMachine.epoll
        
        # Set the maximum number of socket descriptors that the server may open.
        # The process needs to have required privilege to set it higher the 1024 on
        # some systems.
        @maximum_connections = EventMachine.set_descriptor_table_size(@maximum_connections) unless Thin.win?
      end
      
      # Free up resources used by the backend.
      def close
      end
      
      def running?
        @running
      end
            
      # Called by a connection when it's unbinded.
      def connection_finished(connection)
        @persistent_connection_count -= 1 if connection.can_persist?
        @connections.delete(connection)
        
        # Finalize gracefull stop if there's no more active connection.
        stop! if @stopping && @connections.empty?
      end
      
      # Returns +true+ if no active connection.
      def empty?
        @connections.empty?
      end
      
      # Number of active connections.
      def size
        @connections.size
      end
      
      protected
        # Initialize a new connection to a client.
        def initialize_connection(connection)
          connection.backend                 = self
          connection.app                     = @server.app
          connection.comm_inactivity_timeout = @timeout

          # We control the number of persistent connections by keeping
          # a count of the total one allowed yet.
          if @persistent_connection_count < @maximum_persistent_connections
            connection.can_persist!
            @persistent_connection_count += 1
          end

          @connections << connection
        end
      
    end
  end
end