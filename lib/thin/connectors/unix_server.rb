module Thin
  module Connectors    
    class UnixServer < Connector
      # UNIX domain socket on which the server is listening for connections.
      attr_accessor :socket
      
      def initialize(socket)
        raise PlatformNotSupported, 'UNIX sockets not available on Windows' if Thin.win?
        
        @socket = socket
        super()
      end
      
      def connect
        at_exit { remove_socket_file }
        @signature = EventMachine.start_unix_domain_server(@socket, UnixConnection, &method(:initialize_connection))
      end
      
      def disconnect
        EventMachine.stop_server(@signature)
      end
      
      def close
        remove_socket_file
      end
      
      def running?
        !@signature.nil?
      end
      
      def to_s
        @socket
      end
      
      protected
        def remove_socket_file
          File.delete(@socket) if @socket && File.exist?(@socket)
        end
    end
    
    class UnixConnection < Connection
      protected
        def remote_address
          # FIXME not sure about this, does it even make sense on a UNIX socket?
          Socket.unpack_sockaddr_un(get_peername)
        end
    end
  end
end