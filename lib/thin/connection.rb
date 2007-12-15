module Thin
  class Connection < EventMachine::Connection
    include Logging
    
    attr_accessor :app
    
    def post_init
      @env      = {}
      @request  = Request.new(@env)
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
      # Add client info to the request env
      @env['REMOTE_ADDR'] = @env['HTTP_X_FORWARDED_FOR'] || Socket.unpack_sockaddr_in(get_peername)[1]

      @env.update("rack.version"      => [0, 1],
                  "rack.errors"       => STDERR,
                  
                  "rack.multithread"  => false,
                  "rack.multiprocess" => false, # ???
                  "rack.run_once"     => false
                 )

      @response.status, @response.headers, @response.body = @app.call(@env)
      
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