require 'thin_parser'

module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < StandardError; end
  
  class Request
    attr_reader :env, :data, :body
    
    def initialize(env)
      @env      = env
      @parser   = HttpParser.new
      @data     = ''
      @nparsed  = 0
      @body     = StringIO.new
    end
    
    def parse(data)
      @data << data
			
			if @parser.finished?  # Header finished, can only be some more body
        body << data
			elsif @data.size > MAX_HEADER
			  raise InvalidRequest, 'Header longer than allowed'
			else                  # Parse more header
			  @nparsed = @parser.execute(@env, @data, @nparsed)
  			
  			http_body = @env.instance_eval{@http_body}
  			body << http_body if http_body
			end
			
			# Check if header and body are complete
			if @parser.finished? && body.size >= content_length
		    finish
		    return true
		  end
			
			false # Not finished, need more data
    rescue HttpParserError => e
      raise InvalidRequest, e.message
    end
    
    def finish
      # Convert environment to according to Rack specs
      @env.delete "HTTP_CONTENT_TYPE"
      @env.delete "HTTP_CONTENT_LENGTH"
      
      @env["rack.url_scheme"] = "http"
      @env["rack.input"]      = @body
      
      @env["PATH_INFO"]      = @env["REQUEST_URI"] if env["PATH_INFO"].to_s == ""
      @env["SCRIPT_NAME"]    = "" if @env["SCRIPT_NAME"] == "/"
      @env["QUERY_STRING"] ||= ""
      @env.delete "PATH_INFO" if @env["PATH_INFO"] == ""
      
      
      # Add server info to the request env
      @env['SERVER_SOFTWARE'] = SERVER
      
      body.rewind
    end
    
    def content_length
      @env['CONTENT_LENGTH'].to_i
    end
  end  
end