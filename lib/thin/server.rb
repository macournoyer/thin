require 'socket'
require 'fileutils'
require 'logger'
require 'timeout'

module Thin
  # The Thin HTTP server used to served request.
  # It listen for incoming request on a given port
  # and forward all request to all the handlers in the order
  # they were registered.
  # Based on HTTP 1.1
  # See: http://www.w3.org/Protocols/rfc2616/rfc2616.html
  class Server
    attr_accessor :port, :host, :handlers, :timeout
    attr_reader   :logger
    
    # Creates a new server binded to <tt>host:port</tt>
    # that will pass request to +handlers+.
    def initialize(host, port, *handlers)
      @host       = host
      @port       = port
      @handlers   = handlers
      @timeout    = 5      # sec, max time to parse a request
      @stop       = true   # true is server is stopped
      @processing = false  # true is processing a request

      @socket     = TCPServer.new(host, port)
      
      self.logger = Logger.new(STDOUT)
    end
    
    # Set the logger used for the server and all handlers.
    def logger=(logger)
      @logger = logger
      @handlers.each { |h| h.logger = logger }
    end
    
    # Starts the server in the current process.
    def start
      @stop = false
      trap('INT') do
        logger.info '>> Caught INT signal, stopping ...'
        stop
      end
      
      logger.info  ">> Thin web server (v#{VERSION})"
      logger.debug ">> Tracing ON"

      @handlers.each do |handler|
        logger.info ">> Starting #{handler} ..."
        handler.start
      end
      
      logger.info ">> Listening on #{host}:#{port}, CTRL+C to stop"
      until @stop
        @processing = false
        client = @socket.accept rescue nil
        break if @socket.closed? || client.nil?
        @processing = true
        process(client)
      end
    ensure
      @socket.close unless @socket.closed? rescue nil
    end
    
    # Process one request from a client 
    def process(client)
      return if client.eof?
      
      logger.debug { 'Request started'.center(80, '=') }

      request  = Request.new
      response = Response.new
      
      logger.debug { request.trace = true; ">> Tracing request parsing ... " }

      # Parse the request checking for timeout to prevent DOS attacks
      Timeout.timeout(@timeout) { request.parse!(client) }
      logger.debug { request.raw }
      
      # Add client info to the request env
      request.params['REMOTE_ADDR'] = client.peeraddr.last
      
      # Add server info to the request env
      request.params['SERVER_SOFTWARE'] = SERVER
      request.params['SERVER_PORT']     = @port.to_s
      
      served = false
      @handlers.each do |handler|
        served = handler.process(request, response)
        break if served
      end
      
      if served
        logger.debug { ">> Sending response:\n" + response.to_s }
        response.write client
      else
        client << ERROR_404_RESPONSE
      end
      
      logger.debug { 'Request finished'.center(80, '=') }

    rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL, Errno::EBADF
      # Can't do anything sorry, closing the socket in the ensure block
    rescue InvalidRequest => e
      logger.warn "Invalid request: #{e.message}"
      logger.debug { e.backtrace.join("\n") }
      client << ERROR_400_RESPONSE rescue nil
    rescue Object => e
      logger.error "Unexpected error while processing request: #{e.message}"
      logger.error e.backtrace.join("\n")
    ensure
      request.close  if request            rescue nil
      response.close if response           rescue nil
      client.close   unless client.closed? rescue nil
    end
    
    # Stop the server from accepting new request.
    # If a request is processing, wait for this to finish
    # and shutdown the server.
    def stop
      @stop = true
      if !@processing # Not processing, so waiting for a request
        @socket.close rescue nil # Break the accept loop by closing the socket
      end
    end
  end
end