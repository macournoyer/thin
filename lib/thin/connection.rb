require 'socket'

module Thin
  # Connection between the server and client.
  # This class is instanciated by EventMachine on each new connection
  # that is opened.
  class Connection < EventMachine::Connection
    include Logging
    
    # Rack application served by this connection.
    attr_accessor :app
    
    # Connector to the server
    attr_accessor :connector
    
    # Current request served by the connection
    attr_accessor :request
    
    # Next response sent through connection
    attr_accessor :response
    
    # Get the connection ready to process a request.
    def post_init
      @request  = Request.new
      @response = Response.new
    end
    
    # Called when data is received from the client.
    def receive_data(data)
      trace { data }
      process if @request.parse(data)
    rescue InvalidRequest => e
      log "!! Invalid request"
      log_error e
      close_connection
    end
    
    # Called when all data was received and the request
    # is ready to being processed.
    def process
      # Add client info to the request env
      @request.remote_address = remote_address
      
      # Process the request
      @response.status, @response.headers, @response.body = @app.call(@request.env)
      
      # Make the response persistent if requested by the client
      @response.persistent! if @request.persistent?
      
      # Send the response
      @response.each do |chunk|
        trace { chunk }
        send_data chunk
      end
      
      # If no more request on that same connection, we close it.
      close_connection_after_writing unless persistent?
      
    rescue
      log "!! Unexpected error while processing request: #{$!.message}"
      log_error
      close_connection rescue nil
    ensure
      @request.close  rescue nil
      @response.close rescue nil
      
      # Prepare the connection for another request if the client
      # supports HTTP pipelining (persistent connection).
      post_init if persistent?
    end
    
    # Called when the connection is unbinded from the socket
    # and can no longer be used to process requests.
    def unbind
      @connector.connection_finished(self)
    end
    
    # Return +true+ if the connection must be left open
    # and ready to be reused for another request.
    def persistent?
      @response.persistent?
    end
    
    # IP Address of the remote client.
    def remote_address
      @request.forwarded_for || socket_address
    rescue
      log_error
      nil
    end
    
    protected
      def socket_address
        Socket.unpack_sockaddr_in(get_peername)[1]
      end
  end
end