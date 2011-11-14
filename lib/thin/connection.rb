# require "http/parser"
require "thin_parser"
require "eventmachine"

require_relative "request"
require_relative "response"

module Thin
  class Connection < EM::Connection
    attr_accessor :server
    
    ## EM callbacks
    
    def post_init
      # @parser = Http::Parser.new(self)
      @parser = Thin::HttpParser.new
      @body = StringIO.new('')
      @env = {
        'rack.input' => @body
      }
      @data = ''
      @nparsed = 0
    end
    
    def receive_data(data)
      # @parser << data
      
      if @parser.finished?
        @body << data
      else
        @data << data
        @nparsed = @parser.execute(@env, @data, @nparsed)
      end
      
      if @parser.finished? && @body.size >= @env["CONTENT_LENGTH"].to_i
        @data = nil
        on_message_complete
      end
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
      # p @request.to_env
      response = Response.new
      response.status, response.headers, response.body = @server.app.call(@env)
      # response.status, response.headers, response.body = [200, {"Content-Type" => "text/plain"}, ["hi!"]]
      @request = nil
      
      response.headers["Connection"] = "close"
      response.headers["Server"] = "Thin 2.0.0"
      
      response.each { |chunk| send_data chunk }
      
      close_connection_after_writing
    end
  end
end