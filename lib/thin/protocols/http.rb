require "http/parser"

module Thin
  module Protocols
    class Http < EM::Connection
      require "thin/protocols/http/request"
      require "thin/protocols/http/response"
      
      attr_accessor :server
      attr_reader :request
    
      def send_response(response)
        response.finish
        response.each { |chunk| send_data chunk }
      
        close_connection_after_writing
      rescue Exception => e
        $stderr.puts "Error sending response: #{e}"
        close_connection
      end
    
      ## EM callbacks
    
      def post_init
        @parser = HTTP::Parser.new(self)
      end
    
      def receive_data(data)
        @parser << data
      rescue HTTP::Parser::Error => e
        $stderr.puts "Parse error: #{e}"
        send_response Response.error("Bad Request", 400)
      end
    
      def unbind
        @request.close if @request
      end
    
      # Returns IP address of peer as a string.
      def socket_address
        Socket.unpack_sockaddr_in(get_peername)[1]
      rescue Exception => e
        $stderr.puts "Can't get socket address: #{e}"
        nil
      end
    
      ## Parser callbacks
    
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
      
        # Call the Rack application
        response = Response.new(*@server.app.call(@request.env))
      
        # We're done with the request
        @request.close
      
        # Complete and send the response.
        send_response response
      
      rescue Exception => e
        $stderr.puts "Error processing request: #{e}"
        send_response Response.error("Internal Server Error", 500)
      end
    end
  end
end