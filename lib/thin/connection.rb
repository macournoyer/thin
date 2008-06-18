require 'socket'

module Thin
  # Connection between the server and client.
  # This class is instanciated by EventMachine on each new connection
  # that is opened.
  class Connection < EventMachine::Connection
    include Logging
    
    # Rack application (adapter) served by this connection.
    attr_accessor :app
    
    # Backend to the server
    attr_accessor :backend
    
    # Current request served by the connection
    attr_accessor :request
    
    # Next response sent through the connection
    attr_accessor :response
    
    # Calling the application in a threaded allowing
    # concurrent processing of requests.
    attr_writer :threaded
    
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
    # is ready to be processed.
    def process
      if threaded?
        @request.threaded = true
        EventMachine.defer(method(:pre_process), method(:post_process))
      else
        @request.threaded = false
        post_process(pre_process)
      end
    end
    
    def pre_process
      # Add client info to the request env
      @request.remote_address = remote_address

      # Add the async references to env, these can be use to construct 
      # callback targets for the async response.
      @request.env['async.connection'] = self
      @request.env['async.callback'] = :post_process
      
      # Process the request calling the Rack adapter
      response = :async
      catch(:async) do
        response = @app.call(@request.env)
      end
      response
    rescue Object
      handle_error
      terminate_request
      nil # Signal to post_process that the request could not be processed
    end
    
    def post_process(result)
      return unless result
      return if result == :async
      
      @response.status, @response.headers, @response.body = result

      # Make the response persistent if requested by the client
      @response.persistent! if @request.persistent?
      
      # Send the response
      @response.each do |chunk|
        trace { chunk }
        send_data chunk
      end
      
      # If no more request on that same connection, we close it.
      close_connection_after_writing unless persistent?
      
    rescue Object
      handle_error
    ensure
      terminate_request unless result == :async
    end
    
    def handle_error
      log "!! Unexpected error while processing request: #{$!.message}"
      log_error
      close_connection rescue nil
    end
    
    def terminate_request
      @request.close  rescue nil
      @response.close rescue nil
      
      # Prepare the connection for another request if the client
      # supports HTTP pipelining (persistent connection).
      post_init if persistent?
    end
    
    # Called when the connection is unbinded from the socket
    # and can no longer be used to process requests.
    def unbind
      @backend.connection_finished(self)
    end
    
    # Allows this connection to be persistent.
    def can_persist!
      @can_persist = true
    end

    # Return +true+ if this connection is allowed to stay open and be persistent.
    def can_persist?
      @can_persist
    end

    # Return +true+ if the connection must be left open
    # and ready to be reused for another request.
    def persistent?
      @can_persist && @response.persistent?
    end
    
    # +true+ if <tt>app.call</tt> will be called inside a thread.
    # You can set all requests as threaded setting <tt>Connection#threaded=true</tt>
    # or on a per-request case returning +true+ in <tt>app.deferred?</tt>.
    def threaded?
      @threaded || (@app.respond_to?(:deferred?) && @app.deferred?(@request.env))
    end
    
    # IP Address of the remote client.
    def remote_address
      @request.forwarded_for || socket_address
    rescue Object
      log_error
      nil
    end
    
    protected
      def socket_address
        Socket.unpack_sockaddr_in(get_peername)[1]
      end
  end
end