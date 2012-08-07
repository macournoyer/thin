require "rack"
require "http/parser"

require "thin/request"
require "thin/response"
require "thin/chunked_body"

module Thin
  # EventMachine connection.
  # Supports:
  # * Rack specifications v1.1: http://rack.rubyforge.org/doc/SPEC.html
  # * Asynchronous responses with chunked encoding, via the <tt>env['async.callback']</tt> or <tt>throw :async</tt>.
  # * Keep-alive.
  # * File streaming.
  # * Calling the Rack app from pooled threads.
  class Connection < EM::Connection
    attr_accessor :server
    attr_accessor :listener
    attr_accessor :can_keep_alive
  
    # For tests
    attr_reader :request, :response


    def on_close(&block)
      @on_close = block
    end
  

    # == EM callback methods

    # Get the connection ready to process a request.
    def post_init
      @parser = HTTP::Parser.new(self)
    end

    # Called when data is received from the client.
    def receive_data(data)
      puts data if $DEBUG
      @parser << data
    rescue HTTP::Parser::Error => e
      $stderr.puts "Parse error: #{e}"
      send_response_and_reset Response.error(400) # Bad Request
    end

    # Called when the connection is unbinded from the socket
    # and can no longer be used to process requests.
    def unbind
      close_request_and_response
      @on_close.call if @on_close
    end


    # == Parser callback methods

    def on_message_begin
      @request = Request.new
    end

    def on_headers_complete(headers)
      @request.multithread = server.threaded?
      @request.multiprocess = server.prefork?
      @request.remote_address = socket_address
      @request.http_version = "HTTP/%d.%d" % @parser.http_version
      @request.method = @parser.http_method
      @request.path = @parser.request_path
      @request.fragment = @parser.fragment
      @request.query_string = @parser.query_string
      @request.keep_alive = @parser.keep_alive?
      @request.headers = headers
    end

    def on_body(chunk)
      @request << chunk
    end

    def on_message_complete
      @request.finish
      process
    end


    # == Request processing methods
  
    # Starts the processing of the current request in <tt>@request</tt>.
    def process
      if server.threaded?
        EM.defer(method(:call_app), method(:process_response))
      else
        if response = call_app
          process_response(response)
        end
      end
    end

    # Calls the Rack app in <tt>server.app</tt>.
    # Returns a Rack response: <tt>[status, {headers}, [body]]</tt>
    # or +nil+ if there was an error.
    # The app can return [-1, ...] or throw :async to short-circuit request processing.
    def call_app
      # Connection may be closed unless the App#call response was a [-1, ...]
      # It should be noted that connection objects will linger until this 
      # callback is no longer referenced, so be tidy!
      @request.async_callback = method(:process_async_response)

      # Call the Rack application
      response = Response::ASYNC # `throw :async` will result in this response
      catch(:async) do
        response = @server.app.call(@request.env)
      end

      response

    rescue Exception
      handle_error
      nil # Signals that the request could not be processed
    end
  
    def prepare_response(response)
      return unless response
    
      Response.new(*response)
    end

    # Process the response returns by +call_app+.
    def process_response(response)
      @response = prepare_response(response)
    
      # We're going to respond later (async).
      return if @response.async?
    
      # Close the resources used by the request as soon as possible.
      @request.close
    
      # Send the response.
      send_response_and_reset

    rescue Exception
      handle_error
    end
  
    # Process the response sent asynchronously via <tt>body.call</tt>.
    # The response will automatically be send using chunked encoding under
    # HTTP 1.1 protocol.
    def process_async_response(response)
      @response = prepare_response(response)
    
      # Terminate the connection on callback from the response's body.
      @response.body_callback = method(:terminate_async_response)
    
      # Use chunked encoding if available.
      if @request.support_encoding_chunked?
        @response.chunked_encoding!
        @response.body = ChunkedBody.new(@response.body)
      end
    
      # Send the response.
      send_response
    
    rescue Exception
      handle_error
    end
  
    # Called after an asynchronous response is done sending the body.
    def terminate_async_response
      if @request.support_encoding_chunked?
        # Send tail chunk. 0 length signals we're done w/ HTTP chunked encoding.
        send_chunk ChunkedBody::TAIL
      end
    
      reset
    
    rescue Exception
      handle_error
    end
  
    # Reset the connection and prepare for another request if keep-alive is
    # requested.
    # Else, closes the connection.
    def reset
      if @response && @response.keep_alive?
        # Prepare the connection for another request if the client
        # requested a persistent connection (keep-alive).
        post_init
      else
        close_connection_after_writing
      end
    
      close_request_and_response
    end
  
  
    # == Response sending methods
  
    # Send the HTTP response back to the client.
    def send_response(response=@response)
      @response = response
    
      if @request
        # Keep connection alive if requested by the client.
        @response.keep_alive! if @can_keep_alive && @request.keep_alive?
        @response.http_version = @request.http_version
      end
  
      # Prepare the response for sending.
      @response.finish
    
      if @response.file?
        send_file
        return
      end
    
      @response.each(&method(:send_chunk))
      puts if $DEBUG
    
    rescue Exception => e
      # In case there's an error sending the response, we give up and just
      # close the connection to prevent recursion and consuming too much
      # resources.
      $stderr.puts "Error sending response: #{e}"
      close_connection
    end
  
    def send_response_and_reset(response=@response)
      send_response(response)
      reset
    end
  
    # Sending a file using EM streaming and HTTP 1.1 style chunked-encoding if
    # supported by the client.
    def send_file
      # Use HTTP 1.1 style chunked-encoding to send the file if supported
      if @request.support_encoding_chunked?
        @response.chunked_encoding!
        send_chunk @response.head
        deferrable = stream_file_data @response.filename, :http_chunks => true
      else
        send_chunk @response.head
        deferrable = stream_file_data @response.filename
      end
    
      deferrable.callback(&method(:reset))
      deferrable.errback(&method(:reset))
    
      if $DEBUG
        puts "<Serving file #{@response.filename} with streaming ...>"
        puts
      end
    end
  
    def send_chunk(data)
      print data if $DEBUG
      send_data data
    end
  
    private
      # == Support methods
    
      def close_request_and_response
        if @request
          @request.close
          @request = nil
        end
        if @response
          @response.close
          @response = nil
        end
      end
  
      # Returns IP address of peer as a string.
      def socket_address
        if listener.unix?
          ""
        else
          Socket.unpack_sockaddr_in(get_peername)[1]
        end
      rescue Exception => e
        $stderr.puts "Can't get socket address: #{e}"
        ""
      end
  
      # Output the error to stderr and sends back a 500 error.
      def handle_error(e=$!)
        $stderr.puts "[ERROR] #{e}"
        $stderr.puts "\t" + e.backtrace.join("\n\t") if $DEBUG
        send_response_and_reset Response.error(500) # Internal Server Error
      end
  end
end
