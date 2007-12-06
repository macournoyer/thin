module Thin
  class Connection < EventMachine::Connection
    include Logging
    
    attr_accessor :handlers, :host, :port
    
    def post_init
      @request  = Request.new
      @response = Response.new
    end
    
    def receive_data(data)
      trace { 'Request started'.center(80, '=') }

      @request.parse! StringIO.new(data)
      trace { data }
      
      # Add client info to the request env
      @request.params['REMOTE_ADDR'] = @request.params['HTTP_X_FORWARDED_FOR'] || Socket.unpack_sockaddr_in(get_peername)[1]
      
      # Add server info to the request env
      @request.params['SERVER_SOFTWARE'] = SERVER
      @request.params['SERVER_NAME']     = @host
      @request.params['SERVER_PORT']     = @port.to_s
      
      served = false
      @handlers.each do |handler|
        served = handler.process(@request, @response)
        break if served
      end
      
      if served
        trace { ">> Sending response:\n" + @response.to_s }
        @response.send_data_to self
      else
        send_data ERROR_404_RESPONSE
      end
      
      close_connection_after_writing
      
      trace { 'Request finished'.center(80, '=') }
    
    rescue InvalidRequest => e
      log "Invalid request: #{e.message}"
      trace { e.backtrace.join("\n") }
      send_data ERROR_400_RESPONSE
      close_connection_after_writing
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log e.backtrace.join("\n")
      close_connection rescue nil
    ensure
      @request.close  if @request   rescue nil
      @response.close if @response  rescue nil
    end
  end
end