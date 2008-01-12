require 'thin_parser'

module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < IOError; end
  
  # A request sent by the client to the server.
  class Request
    MAX_HEADER        = 1024 * (80 + 32)
    MAX_HEADER_MSG    = 'Header longer than allowed'.freeze

    SERVER_SOFTWARE   = 'SERVER_SOFTWARE'.freeze
    REMOTE_ADDR       = 'REMOTE_ADDR'.freeze
    FORWARDED_FOR     = 'HTTP_X_FORWARDED_FOR'.freeze

    CONTENT_LENGTH    = 'CONTENT_LENGTH'.freeze

    RACK_INPUT        = 'rack.input'.freeze
    RACK_VERSION      = 'rack.version'.freeze
    RACK_ERRORS       = 'rack.errors'.freeze
    RACK_MULTITHREAD  = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE     = 'rack.run_once'.freeze
    
    attr_reader :env, :data, :body
    
    def initialize
      @parser   = HttpParser.new
      @data     = ''
      @nparsed  = 0
      @body     = StringIO.new
      @env      = {
        SERVER_SOFTWARE   => SERVER,
        
        # Rack stuff
        RACK_INPUT        => @body,
        
        RACK_VERSION      => [0, 2],
        RACK_ERRORS       => STDERR,
        
        RACK_MULTITHREAD  => false,
        RACK_MULTIPROCESS => false,
        RACK_RUN_ONCE     => false
      }
    end
    
    def parse(data)
      @data << data
			
			if @parser.finished?                    # Header finished, can only be some more body
        body << data
			elsif @data.size > MAX_HEADER           # Oho! very big header, must be a bad person
			  raise InvalidRequest, MAX_HEADER_MSG
			else                                    # Parse more header
			  @nparsed = @parser.execute(@env, @data, @nparsed)
			end
			
			# Check if header and body are complete
			if @parser.finished? && body.size >= content_length
		    body.rewind
		    return true # Request is fully parsed
		  end
			
			false # Not finished, need more data
    end
    
    def content_length
      @env[CONTENT_LENGTH].to_i
    end
  end  
end