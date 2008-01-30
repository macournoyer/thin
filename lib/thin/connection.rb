require 'socket'

module Thin
  class Connection < EventMachine::Connection
    include Logging
    
    # Rack application served by this connection.
    attr_accessor :app
    
    # +true+ if the connection is on a UNIX domain socket.
    attr_accessor :unix_socket
    
    # Server owning the connection
    attr_accessor :server
    
    def post_init
      @request  = Request.new
      @response = Response.new
    end
    
    def receive_data(data)
      trace { data }
      process if @request.parse(data)
    rescue InvalidRequest => e
      log "Invalid request"
      log_error e
      close_connection
    end
    
    def process
      # Add client info to the request env
      @request.env[Request::REMOTE_ADDR] = remote_address
      
      # Process the request
      @response.status, @response.headers, @response.body = @app.call(@request.env)
      
      # Send the response
      @response.each do |chunk|
        trace { chunk }
        send_data chunk
      end
      
      close_connection_after_writing
      
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log_error e
      close_connection rescue nil
    ensure
      @request.close  rescue nil
      @response.close rescue nil
    end
    
    def unbind
      @server.connection_finished(self)
    end
    
    protected
      def remote_address
        if remote_addr = @request.env[Request::FORWARDED_FOR]
          remote_addr
        elsif @unix_socket
          # FIXME not sure about this, does it even make sense on a UNIX socket?
          Socket.unpack_sockaddr_un(get_peername)
        else
          Socket.unpack_sockaddr_in(get_peername)[1]
        end
      end
  end
end