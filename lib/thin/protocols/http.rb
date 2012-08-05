require "http/parser"

module Thin
  module Protocols
    # EventMachine HTTP protocol.
    # Supports:
    # * Rack specifications v1.1: http://rack.rubyforge.org/doc/SPEC.html
    # * Asynchronous responses, via the <tt>env['async.callback']</tt> or <tt>throw :async</tt>.
    # * Keep-alive.
    # * File streaming.
    class Http < EM::Connection
      # Http class has to be defined before requiring those.
      require "thin/protocols/http/request"
      require "thin/protocols/http/response"
      
      attr_accessor :server
      attr_accessor :listener
      
      attr_reader :request, :response


      # == EM callbacks

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
        @request.close if @request
        @response.close if @response
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


      # == Parser callbacks

      def on_message_begin
        @request = Request.new
        @request.remote_address = socket_address
      end

      def on_headers_complete(headers)
        @request.http_version = @parser.http_version
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

        if response = call_app
          process(response)
        end
      end


      # == Request processing

      def call_app
        # Connection may be closed unless the App#call response was a [-1, ...]
        # It should be noted that connection objects will linger until this 
        # callback is no longer referenced, so be tidy!
        @request.async_callback = method(:process)

        # Call the Rack application
        response = Response::ASYNC
        catch(:async) do
          response = @server.app.call(@request.env)
        end

        # We're done with the request
        @request.close

        response

      rescue Exception
        handle_error
        nil # Signals that the request could not be processed
      end

      def process(response)
        @response = Response.new(*response)

        # We're going to respond later (async).
        return if @response.async?
        
        # If the body is being deferred, then terminate afterward.
        @response.callback = method(:reset) if @response.callback?

        # Send the response.
        send_response

      rescue Exception
        handle_error
      end
      
      def send_response(response=@response)
        @response = response
        
        # Keep connection alive if requested by the client
        @response.keep_alive! if @request && @request.keep_alive?
        
        @response.finish
        
        if @response.file?
          send_file
          return
        end
        
        @response.each do |chunk|
          print chunk if $DEBUG
          send_data chunk
        end
        puts if $DEBUG
        
        reset
        
      rescue Exception => e
        # In case there's an error sending, we don't bother sending an error code
        # which might cause another error.
        $stderr.puts "Error sending response: #{e}"
        close_connection
      end
      
      # Sending a file using EM streaming and HTTP 1.1 style chunked-encoding if
      # supported by client.
      def send_file
        # Use HTTP 1.1 style chunked-encoding to send the file if supported
        if @request.support_encoding_chunked?
          @response.headers['Transfer-Encoding'] = 'chunked'
          send_data @response.head
          deferrable = stream_file_data @response.filename, :http_chunks => true
        else
          send_data @response.head
          deferrable = stream_file_data @response.filename
        end
        
        deferrable.callback(&method(:reset))
        deferrable.errback(&method(:reset))
        
        if $DEBUG
          puts @response.head
          puts "<Serving file #{@response.filename} with streaming ...>"
          puts
        end
      end
      
      def handle_error(e=$!)
        $stderr.puts "Error processing request: #{e}"
        $stderr.print "#{e}\n\t" + e.backtrace.join("\n\t") if $DEBUG
        send_response Response.error(500) # Internal Server Error
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
        
        if @request
          @request.close
          @request = nil
        end
        if @response
          @response.close
          @response = nil
        end
      end
    end
  end
end
