require 'socket'
require 'fileutils'
require 'timeout'

module Thin
  # The Thin HTTP server used to served request.
  # It listen for incoming request on a given port
  # and forward all request to all the handlers in the order
  # they were registered.
  # Based on HTTP 1.1
  # See: http://www.w3.org/Protocols/rfc2616/rfc2616.html
  class Server
    include Logging
    include Daemonizable
    
    # Addresse and port on which the server is listening for connections.
    attr_accessor :port, :host
    
    # List of handlers to process the request in the order they are given.
    attr_accessor :handlers
    
    # Maximum time for a request to be red and parsed.
    attr_accessor :timeout
    
    # Creates a new server binded to <tt>host:port</tt>
    # that will pass request to +handlers+.
    def initialize(host, port, *handlers)
      @host       = host
      @port       = port
      @handlers   = handlers
      @timeout    = 60     # sec, max time to read and parse a request
      @trace      = false

      @stop       = true   # true is server is stopped
      @processing = false  # true is processing a request

      @socket     = TCPServer.new(host, port)
    end
    
    # Starts the server in the current process.
    def start
      @stop = false
      trap('INT') do
        log '>> Caught INT signal, stopping ...'
        stop
      end
      
      log   ">> Thin web server (v#{VERSION})"
      trace ">> Tracing ON"

      @handlers.each do |handler|
        log ">> Starting #{handler} ..."
        handler.start
      end
      
      log ">> Listening on #{host}:#{port}, CTRL+C to stop"
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
      
      trace { 'Request started'.center(80, '=') }

      request  = Request.new
      response = Response.new
      
      request.trace = @trace
      trace { ">> Tracing request parsing ... " }

      # Parse the request checking for timeout to prevent DOS attacks
      Timeout.timeout(@timeout) { request.parse!(client) }
      trace { request.raw }
      
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
        trace { ">> Sending response:\n" + response.to_s }
        response.write client
      else
        client << ERROR_404_RESPONSE
      end
      
      trace { 'Request finished'.center(80, '=') }

    rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL, Errno::EBADF
      # Can't do anything sorry, closing the socket in the ensure block
    rescue InvalidRequest => e
      log "Invalid request: #{e.message}"
      trace { e.backtrace.join("\n") }
      client << ERROR_400_RESPONSE rescue nil
    rescue Object => e
      log "Unexpected error while processing request: #{e.message}"
      log e.backtrace.join("\n")
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
      stop! unless @processing  # Not processing a request, so we can stop now
    end
    
    # Force the server to stop right now!
    def stop!
      @socket.close rescue nil # break the accept loop by closing the socket
    end
  end
end