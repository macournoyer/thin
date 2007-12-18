require 'thin_parser'

module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < IOError; end
  
  class Request
    MAX_HEADER      = 1024 * (80 + 32)
    MAX_HEADER_MSG  = 'Header longer than allowed'.freeze
    RACK_INPUT      = 'rack.input'.freeze
    SERVER_SOFTWARE = 'SERVER_SOFTWARE'.freeze
    CONTENT_LENGTH  = 'CONTENT_LENGTH'.freeze
    
    attr_reader :env, :data, :body
    
    def initialize
      @parser   = HttpParser.new
      @data     = ''
      @nparsed  = 0
      @body     = StringIO.new
      @env      = {
        RACK_INPUT      => @body,
        SERVER_SOFTWARE => SERVER,
        
        # Rack stuff
        "rack.version"      => [0, 1],
        "rack.errors"       => STDERR,
        
        "rack.multithread"  => false,
        "rack.multiprocess" => false,
        "rack.run_once"     => false
      }
    end
    
    def parse(data)
      @data << data
			
			if @parser.finished?  # Header finished, can only be some more body
        body << data
			elsif @data.size > MAX_HEADER
			  raise InvalidRequest, MAX_HEADER_MSG
			else                  # Parse more header
			  @nparsed = @parser.execute(@env, @data, @nparsed)
			end
			
			# Check if header and body are complete
			if @parser.finished? && body.size >= content_length
		    finish
		    return true
		  end
			
			false # Not finished, need more data
    end
    
    def finish
      # Convert environment to according to Rack specs
      @env["PATH_INFO"]      = @env["REQUEST_URI"] if env["PATH_INFO"].to_s == ""
      @env["SCRIPT_NAME"]    = "" if @env["SCRIPT_NAME"] == "/"
      @env["QUERY_STRING"] ||= ""
      @env.delete "PATH_INFO" if @env["PATH_INFO"] == ""
      
      
      
      body.rewind
    end
    
    def content_length
      @env[CONTENT_LENGTH].to_i
    end
  end  
end