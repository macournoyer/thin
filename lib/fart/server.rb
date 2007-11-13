require 'socket'

module Fart
  class Server
    attr_reader :port, :host, :handlers
    
    def initialize(host, port, *handlers)
      @host     = host
      @port     = port
      @handlers = handlers
      @stop     = false

      @socket   = TCPServer.new(host, port)
    end
    
    def logger
      LOGGER
    end
    
    def run
      @stop = false
      trap('INT') { stop }
      
      logger.info "Fart web server - v#{VERSION}"
      logger.info "Listening on #{host}:#{port}"
      until @stop
        client = @socket.accept rescue nil
        break if @socket.closed?
        process(client)
      end
    ensure
      @socket.close unless @socket.closed?
    end
    
    def process(client)
      data     = client.readpartial(CHUNK_SIZE)
      request  = Request.new(data)
      response = Response.new
      
      # Add client info to the request env
      request.params['REMOTE_ADDR'] = client.peeraddr.last

      start_time = Time.now
      logger.debug {"Handling request: #{request}"}

      served = false
      @handlers.each do |handler|
        served = handler.process(request, response)
        break if served
      end
      
      logger.debug {"Sending response: #{response}"}
      
      if served
        response.write client
      else
        client.write ERROR_404_RESPONSE
      end

      request.close
      response.close
      client.close
      
      logger.debug {"Request handled in #{Time.now-start_time} sec"}
    rescue InvalidRequest => e
      logger.error "Invalid request : #{e.message}"
    end
    
    def stop
      logger.info 'Stopping...'
      @stop = true
      @socket.close
    end
  end
end