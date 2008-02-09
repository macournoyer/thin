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
      @request.remote_address = remote_address
      
      # Process the request
      @response.status, @response.headers, @response.body = @app.call(@request.env)
      
      # Tell the client the connection is persistent if requested
      @response.persistent! if @request.persistent?
      
      # Send the response
      @response.each do |chunk|
        trace { chunk }
        send_data chunk
      end
      
      # If no more request on that same connection, we close it.
      close_connection_after_writing unless persistent?
      
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log_error e
      close_connection rescue nil
    ensure
      @request.close  rescue nil
      @response.close rescue nil
      
      # Prepare the connection for another request if the client
      # supports HTTP pipelining (persistent connection).
      post_init if persistent?
    end
    
    def unbind
      @connector.connection_finished(self)
    end
    
    def persistent?
      @response.persistent?
    end
    
    protected
      def remote_address
        @request.forwarded_for || Socket.unpack_sockaddr_in(get_peername)[1]
      end
  end
end