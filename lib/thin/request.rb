module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < StandardError; end
  
  class Request
    attr_reader :env, :data
    
    def initialize(env)
      @env      = env
      @parser   = Mongrel::HttpParser.new
      @data     = ''
      @nparsed  = 0
      
      @env["rack.input"] = StringIO.new
    end
    
    def parse(data)
      @data << data
			@nparsed = @parser.execute(@env, @data, @nparsed) unless @parser.finished?
			
			if @parser.finished?
			  if body
          body << data
  			else
  			  self.body = StringIO.new
  			end
  			if body.size >= content_length
			    finish
			    return true # Request completed
			  end
			elsif @data.size > MAX_HEADER
			  raise InvalidRequest, 'Header longer than allowed'
			end
			
			false # Not finished
    rescue InvalidRequest => e
      raise e
    rescue Exception => e
      raise InvalidRequest, e.message
    end
    
    def body
      @env["rack.input"]
    end
    
    def body=(value)
      @env["rack.input"] = value
    end
    
    def finish
      @env.delete "HTTP_CONTENT_TYPE"
      @env.delete "HTTP_CONTENT_LENGTH"
      
      @env["rack.url_scheme"] = "http"
      
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