require "http/parser"

module Thin
  module Protocols
    class Http < EM::Connection
      # Ensure Http class is defined before requiring those.
      require "thin/protocols/http/request"
      require "thin/protocols/http/response"
      
      attr_accessor :server
      attr_accessor :listener
      
      attr_reader :request, :response

      def send_response(response, close_after=true)
        response.finish
        response.each { |chunk| send_data chunk }

        if close_after
          response.close
          close_connection_after_writing
        end
        true
      rescue Exception => e
        $stderr.puts "Error sending response: #{e}"
        close_connection
        false
      end

      # == EM callbacks

      # Get the connection ready to process a request.
      def post_init
        @parser = HTTP::Parser.new(self)
      end

      # Called when data is received from the client.
      def receive_data(data)
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
        @request.method = @parser.http_method
        @request.path = @parser.request_path
        @request.fragment = @parser.fragment
        @request.query_string = @parser.query_string
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
        nil # Signals to post_process that the request could not be processed
      end

      def process(response)
        @response = Response.new(*response)

        # We're going to respond later (async).
        return if @response.async?

        # Send the response.
        return unless send_response @response, false

        # If the body is being deferred, then terminate afterward.
        if @response.callback?
          @response.callback = method(:reset)
        else
          reset
        end

      rescue Exception
        handle_error
      end
      
      def handle_error(e=$!)
        $stderr.puts "Error processing request: #{e}"
        $stderr.print "#{e}\n\t" + e.backtrace.join("\n\t") if $DEBUG
        send_response Response.error(500) # Internal Server Error
      end

      # Resets the connection
      def reset
        close_connection_after_writing rescue nil
      end
    end
  end
end
