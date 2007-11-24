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
      @host     = host
      @port     = port
      @handlers = handlers
      @stop     = true

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
        logger.info ">> Starting #{handler.class.name} ..."
        handler.start
      end
      
      logger.info ">> Listening on #{host}:#{port}, CTRL+C to stop"      
      until @stop
        client = @socket.accept rescue nil
        break if @socket.closed?
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
      client.close rescue nil
    rescue InvalidRequest => e
      logger.error "Invalid request: #{e.message}"
      logger.error "Request data:\n#{data}"
      client.write ERROR_404_RESPONSE rescue nil
    rescue Object => e
      logger.error "Unexpected error while processing request: #{e.inspect}"
      logger.error e.backtrace.join("\n")
    ensure
      request.close  if request            rescue nil
      response.close if response           rescue nil
      client.close   unless client.closed? rescue nil
    end
    
    # Send the command to stop the server
    def stop
      @stop = true
      @socket.close rescue nil
    end
  end
end