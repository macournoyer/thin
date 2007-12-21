require 'socket'

module Thin
  class Connection < EventMachine::Connection
    include Logging
    
    attr_accessor :app
    
    def post_init
      @request  = Request.new
      @response = Response.new
    end
    
    def receive_data(data)
			process if @request.parse(data)
    rescue InvalidRequest => e
      log "Invalid request"
      log_error e
      trace { data }
      close_connection
    end
    
    def process
      env = @request.env
      
      # Add client info to the request env
      env[Request::REMOTE_ADDR] = env[Request::FORWARDED_FOR] || Socket.unpack_sockaddr_in(get_peername)[1]

      # Process the request
      @response.status, @response.headers, @response.body = @app.call(env)
      
      # Send the response
      send_data @response.head
      @response.body.rewind
      send_data @response.body.read
      
      close_connection_after_writing
      
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log_error e
      close_connection rescue nil
    ensure
      @response.close rescue nil
    end
  end
end