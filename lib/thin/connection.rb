require 'socket'

module Thin
  # Connection between the server and client.
  class Connection < EventMachine::Connection
    include Logging
    
    # Rack application served by this connection.
    attr_accessor :app
    
    # Connector to the server
    attr_accessor :connector
    
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
      
      close_connection_after_writing unless persistent?
      
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log_error e
      close_connection rescue nil
    ensure
      @request.close  rescue nil
      @response.close rescue nil
      
      post_init if persistent?
    end
    
    def unbind
      @connector.connection_finished(self)
    end
    
    def persistent?
      false
    end
    
    protected
      def remote_address
        @request.env[Request::FORWARDED_FOR] || Socket.unpack_sockaddr_in(get_peername)[1]
      end
  end
end