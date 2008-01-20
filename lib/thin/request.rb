require 'thin_parser'
require 'tempfile'

module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < IOError; end
  
  # A request sent by the client to the server.
  class Request
    # Maximum request body size before it is moved out of memory
    # and into a tempfile for reading.
    MAX_BODY          = 1024 * (80 + 32)
    BODY_TMPFILE      = 'thin-body'.freeze

    # Freeze some HTTP header names
    SERVER_SOFTWARE   = 'SERVER_SOFTWARE'.freeze
    REMOTE_ADDR       = 'REMOTE_ADDR'.freeze
    FORWARDED_FOR     = 'HTTP_X_FORWARDED_FOR'.freeze
    CONTENT_LENGTH    = 'CONTENT_LENGTH'.freeze

    # Freeze some Rack header names
    RACK_INPUT        = 'rack.input'.freeze
    RACK_VERSION      = 'rack.version'.freeze
    RACK_ERRORS       = 'rack.errors'.freeze
    RACK_MULTITHREAD  = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE     = 'rack.run_once'.freeze
    
    # CGI-like request environment variables
    attr_reader :env
    
    # Unparsed data of the request
    attr_reader :data
    
    # Request body
    attr_reader :body
    
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
    
    # Parse a chunk of data into the request environment
    # Raises a +InvalidRequest+ if invalid.
    # Returns +true+ if the parsing is complete.
    def parse(data)
      @data << data
			
			if @parser.finished?                    # Header finished, can only be some more body
        body << data
			else                                    # Parse more header using the super parser
			  @nparsed = @parser.execute(@env, @data, @nparsed)
			  # Transfert to a tempfile if body is very big
			  move_body_to_tempfile if @parser.finished? && content_length > MAX_BODY
			end
			
			# Check if header and body are complete
			if @parser.finished? && @body.size >= content_length
		    @body.rewind
		    return true # Request is fully parsed
		  end
			
			false # Not finished, need more data
    end
    
    # Expected size of the body
    def content_length
      @env[CONTENT_LENGTH].to_i
    end
    
    def close
      @body.close if @body === Tempfile
    end
    
    private
      def move_body_to_tempfile
        current_body = @body
		    @body = Tempfile.new(BODY_TMPFILE)
		    @body.binmode
		    @body << current_body unless current_body.size.zero?
		    @env[RACK_INPUT] = @body
      end
  end  
end