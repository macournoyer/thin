require "http/parser"
require "eventmachine"

require "thin/request"
require "thin/response"

module Thin
  class Connection < EM::Connection
    attr_accessor :server
    
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
    
    ## Parser callbacks
    
    def on_message_begin
      @request = Request.new
    end
    
    def on_headers_complete(headers)
      @request.headers = headers
    end
    
    def on_body(chunk)
      @request << chunk
    end
    
    def on_message_complete
      response = Response.new
      response.status, response.headers, response.body = @server.app.call(@request.env)
      
      # We're done with the request, not need to keep that in memory.
      @request.close
      @request = nil
      
      # Complete and send the response.
      response.finish
      response.each { |chunk| send_data chunk }
      
      close_connection_after_writing
    end
  end
end