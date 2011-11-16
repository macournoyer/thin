require "http/parser"
require "eventmachine"

require "thin/request"
require "thin/response"

module Thin
  class Connection < EM::Connection
    attr_accessor :server
    attr_reader :request
    
    ## EM callbacks
    
    def post_init
      @parser = Http::Parser.new(self)
    end
    
    def receive_data(data)
      @parser << data
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
      response = Response.new
      
      # Call the Rack application
      response.status, response.headers, response.body = @server.app.call(@request.env)
      
      # We're done with the request
      @request.close
      
      # Complete and send the response.
      response.finish
      response.each { |chunk| send_data chunk }
      
      close_connection_after_writing
    end
  end
end