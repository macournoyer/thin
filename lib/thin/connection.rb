require "http/parser"

module Thin
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
      send_response Response.error(400) # Bad Request
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
      @request.multiprocess = server.prefork?
      @request.remote_address = socket_address
      @request.http_version = "HTTP/#{@parser.http_version[0]}.#{@parser.http_version[1]}"
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
  
    # Calls the Rack app in <tt>server.app</tt> and sends the response.
    def process
      @request.env['thin.connection'] = self

      # Call the Rack application
      send_response @server.app.call(@request.env)

    rescue Exception
      handle_error
      nil # Signals that the request could not be processed
    end
   
    # Send the HTTP response back to the client.
    def send_response(response)
      @response.close if @response
      @response = Response.new(*response)

      defer = @response.headers.delete('X-Thin-Defer')

      # Defer the entire response. We're going to respond later.
      return if defer == 'response'

      if @request
        # Keep connection alive if requested by the client.
        @response.keep_alive! if @can_keep_alive && @request.keep_alive?
        @response.http_version = @request.http_version
      end
  
      # Prepare the response for sending.
      @response.finish

      # Send the head (status & headers)
      write @response.head

      # Send the body
      @response.body.each { |chunk| write chunk }

      trigger 'send'

      close unless defer == 'close'
    
    rescue Exception => e
      # In case there's an error sending the response, we give up trying to send a proper response.
      $stderr.puts "Error sending response, closing connection."
      log_error
      close_connection
      close_request_and_response
    end
    alias call send_response

    # Reset the connection and prepare for another request if keep-alive is
    # requested.
    # Else, closes the connection.
    def close
      trigger 'close'

      if @response && @response.keep_alive?
        # Prepare the connection for another request if the client
        # requested a persistent connection (keep-alive).
        post_init
      else
        close_connection_after_writing
      end
    
      close_request_and_response
    end
  
    def write(data)
      print data if $DEBUG
      send_data data
    end
    alias << write

  
    private
      def trigger(event)
        # TODO should support several callbacks
        if callback = @request && @request.env["thin.on_#{event}"]
          callback.call
        end
      end
    
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
        # We cache the value to optimize for persistent connection (keep-alive).
        # This can't change if the connection is persistent.
        @socket_address ||= begin
          if listener.unix?
            ""
          else
            Socket.unpack_sockaddr_in(get_peername)[1]
          end
        rescue Exception => e
          $stderr.puts "Can't get socket address: #{e}"
          ""
        end
      end

      def log_error(e=$!)
        $stderr.puts "[ERROR] #{e}"
        $stderr.puts "\t" + e.backtrace.join("\n\t")
      end
  
      # Output the error to stderr and sends back a 500 error.
      def handle_error(e=$!)
        log_error e
        send_response Response.error(500) # Internal Server Error
      end
  end
end
