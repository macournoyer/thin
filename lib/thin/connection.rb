module Thin
  # reload this file in turbo and add subclass
  class Connection < EventMachine::Connection
    include Logging
    
    attr_accessor :handlers
    
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
      trace { 'Request started'.center(80, '=') }
      trace { @request.data }
      
      # Add client info to the request env
      @request.params['REMOTE_ADDR'] = @request.params['HTTP_X_FORWARDED_FOR'] || Socket.unpack_sockaddr_in(get_peername)[1]
      
      # Add server info to the request env
      @request.params['SERVER_SOFTWARE'] = SERVER
      
      served = false
      @handlers.each do |handler|
        served = handler.process(@request, @response)
        break if served
      end
      
      if served
        trace { ">> Sending response:\n" + @response.to_s }
        send_data @response.head
        @response.body.rewind
        send_data @response.body.read
      else
        send_data ERROR_404_RESPONSE
      end
      
      close_connection_after_writing
      
      trace { 'Request finished'.center(80, '=') }
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log_error
      close_connection rescue nil
    ensure
      @request.close  if @request   rescue nil
      @response.close if @response  rescue nil
    end
  end
end