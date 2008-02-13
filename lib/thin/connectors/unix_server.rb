module Thin
  module Connectors
    # Connector to act as a UNIX domain socket server.
    class UnixServer < Connector
      # UNIX domain socket on which the server is listening for connections.
      attr_accessor :socket
      
      def initialize(socket)
        raise PlatformNotSupported, 'UNIX sockets not available on Windows' if Thin.win?
        @socket = socket
        super()
      end
      
      # Connect the server
      def connect
        at_exit { remove_socket_file } # In case it crashes
        EventMachine.start_unix_domain_server(@socket, UnixConnection, &method(:initialize_connection))
        # HACK EventMachine.start_unix_domain_server doesn't return the connection signature
        #      so we have to go in the internal stuff to find it.
        @signature = EventMachine.instance_eval{@acceptors.keys.first}
      end
      
      # Stops the server
      def disconnect
        EventMachine.stop_server(@signature)
      end
      
      # Free up resources used by the connector.
      def close
        remove_socket_file
      end
      
      def to_s
        @socket
      end
      
      protected
        def remove_socket_file
          File.delete(@socket) if @socket && File.exist?(@socket)
        end
    end    
  end

  # Connection through a UNIX domain socket.
  class UnixConnection < Connection
    def remote_address
      # FIXME not sure about this, does it even make sense on a UNIX socket?
      Socket.unpack_sockaddr_un(get_peername)
    rescue
      log_error($!)
      nil
    end
  end
end