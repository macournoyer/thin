require "socket"

module Thin
  class Listener
    attr_reader :host
    
    attr_reader :port
    
    def initialize(host, port)
      @host = host
      @port = port
    end
    
    def socket
      return @socket if @socket
      
      @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      @socket.bind(Socket.pack_sockaddr_in(port, host || ""))
      
      @socket
    end
    
    def tcp_no_delay=(value)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, value)
    end
    
    def listen(backlog)
      socket.listen(backlog)
    end
    
    def close
      socket.close if @socket
    end
    
    def to_s
      (@host || "*") + ":#{@port}"
    end
    
    def self.parse(address)
      case address
      when Integer
        new nil, address
      when /\A(?:\*:)?(\d+)\z/ # *:port or "port"
        new nil, $1.to_i
      when /\A((?:\d{1,3}\.){3}\d{1,3}):(\d+)\z/ # 0.0.0.0:port
        new $1, $2.to_i
      else
        raise ArgumentError, "Invalid address #{address.inspect}. " +
                             "Accepted formats are: 3000, *:3000 or 0.0.0.0:3000"
      end
    end
  end
end