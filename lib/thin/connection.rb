require 'socket'

module Thin
  # Connection between the server and client.
  # This class is instanciated by EventMachine on each new connection
  # that is opened.
  class Connection < EventMachine::Connection
    include Logging
    
    # This is a template async response. N.B. Can't use string for body on 1.9
    AsyncResponse = [100, {}, []].freeze
    
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

      # TODO - remove excess documentation / move it somewhere more sensible.
      # (interface specs!) - (rack)
      
      # Connection may be closed unless the App#call response was a [100, ...]
      # It should be noted that connection objects will linger until this 
      # callback is no longer referenced, so be tidy!
      @request.env['async.callback'] = method(:post_process)
      
      # When we're under a non-async framework like rails, we can still spawn
      # off async responses using the callback info, so there's little point
      # in removing this.
      response = AsyncResponse
      catch(:async) do
        # Process the request calling the Rack adapter
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
      result = result.to_a
      
      # Status code 100 indicates that we're going to respond later (async).
      return if result.first == 100
      
      @response.status, @response.headers, @response.body = *result

      # Make the response persistent if requested by the client
      @response.persistent! if @request.persistent?
      
      # Send the response
      @response.each do |chunk|
        trace { chunk }
        send_data chunk
      end
      
      unless persistent?
        # If the body is deferred, then close_connection needs to happen after
        # the last chunk has been sent.
        if @response.body.kind_of?(EventMachine::Deferrable)
          @response.body.callback { close_connection_after_writing }
          @response.body.errback  { close_connection_after_writing }
        else
          # If no more request or data on that same connection, we close it.
          close_connection_after_writing
        end
      end
      
    rescue Object
      handle_error
    ensure
      # If the body is being deferred, then terminate afterward.
      if @response.body.kind_of?(EventMachine::Deferrable)
        @response.body.callback { terminate_request }
      else
        # Don't terminate the response if we're going async.
        terminate_request unless result && result.first == 100
      end
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
      if @response.body.kind_of?(EventMachine::Deferrable)
        @response.body.fail
      end
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