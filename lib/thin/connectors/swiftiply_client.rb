module Thin
  module Connectors
    class SwiftiplyClient < Connector
      attr_accessor :key
      
      attr_accessor :host, :port
      
      def initialize(host, port, key=nil)
        @host = host
        @port = port.to_i
        @key  = key || ''
        super()
      end

      # Connect the server
      def connect
        EventMachine.connect(@host, @port, SwiftiplyConnection, &method(:initialize_connection))
      end

      # Stops the server
      def disconnect
        EventMachine.stop
      end

      def to_s
        "#{@host}:#{@port} swiftiply"
      end
    end    
  end

  class SwiftiplyConnection < Connection
    def connection_completed
      send_data swiftiply_handshake(@connector.key)
    end
    
    def persistent?
      true
    end
    
    def unbind
      super
      EventMachine.add_timer(rand(2)) { reconnect(@connector.host, @connector.port) } if @connector.running?
    end
    
    protected
      def swiftiply_handshake(key)
        'swiftclient' << host_ip.collect { |x| sprintf('%02x', x.to_i)}.join << sprintf('%04x', @connector.port) << sprintf('%02x', key.length) << key
      end
      
      # For some reason Swiftiply request the current host
      def host_ip
        Socket.gethostbyname(@connector.host)[3].unpack('CCCC') rescue [0,0,0,0]
      end
  end
end