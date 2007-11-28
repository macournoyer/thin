require 'socket'
require 'fileutils'
require 'logger'
require 'timeout'

module Thin
  # The Thin server used to served request.
  # It listen for incoming request on a given port
  # and forward all request to all the handlers in the order
  # they were registered.
  class Server
    attr_accessor :port, :host, :handlers
    
    # Creates a new server binded to <tt>host:port</tt>
    # that will pass request to +handlers+.
    def initialize(host, port, *handlers)
      @host       = host
      @port       = port
      @handlers   = handlers
      @stop       = true   # true is server is stopped
      @processing = false  # true is processing a request

      @socket   = TCPServer.new(host, port)
      
      self.logger = Logger.new(STDOUT)
    end
    
    # Returns the server logger.
    def logger
      @logger
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
      
      logger.info ">> Thin web server (v#{VERSION})"

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
      
      data     = client.readpartial(CHUNK_SIZE)
      request  = Request.new(data)
      response = Response.new
      
      # Read the request to the end if not complete yet
      if request.content_length > 0
        until request.complete?
          chunk = client.readpartial(CHUNK_SIZE) 
          break unless chunk && chunk.size > 0
          request.body << chunk
        end
      end
      
      request.body.rewind
      
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
        response.write client
      else
        client.write ERROR_404_RESPONSE
      end

    rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL, Errno::EBADF
      # Can't do anything sorry, closing the socket in the ensure block
    rescue InvalidRequest => e
      logger.warn "Invalid request: #{e.message}"
      logger.warn "Request data:\n#{data}"
      client.write ERROR_400_RESPONSE rescue nil
    rescue Object => e
      logger.error "Unexpected error while processing request: #{e.inspect}"
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