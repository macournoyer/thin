module Thin
  module Backends
    # Backend to act as a UNIX domain socket server.
    class UnixServer < Base
      # UNIX domain socket on which the server is listening for connections.
      attr_accessor :socket
      
      def initialize(socket)
        raise PlatformNotSupported, 'UNIX domain sockets not available on Windows' if Thin.win?
        check_event_machine_version
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
      
      # Free up resources used by the backend.
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
        
        def check_event_machine_version
          # TODO remove this crap once eventmachine 0.11.0 is released
          begin
            gem 'eventmachine', '>= 0.11.0'
          rescue Gem::LoadError
            raise LoadError, "UNIX domain sockets require EventMachine version 0.11.0 or higher, " +
                             "install the (not yet released) gem with: " +
                             "gem install eventmachine --source http://code.macournoyer.com"
          end
        end
    end    
  end

  # Connection through a UNIX domain socket.
  class UnixConnection < Connection
    protected
      def socket_address        
        '127.0.0.1' # Unix domain sockets can only be local
      end
  end
end