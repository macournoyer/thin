require "stringio"

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
    MAX_HEADER        = 1024 * (80 + 32)
    
    INITIAL_BODY = ''
    # Force external_encoding of request's body to ASCII_8BIT
    INITIAL_BODY.encode!(Encoding::ASCII_8BIT) if INITIAL_BODY.respond_to?(:encode!)
    
    # Freeze some HTTP header names & values
    SERVER_SOFTWARE   = 'SERVER_SOFTWARE'.freeze
    SERVER_NAME       = 'SERVER_NAME'.freeze
    LOCALHOST         = 'localhost'.freeze
    HTTP_VERSION      = 'HTTP_VERSION'.freeze
    HTTP_1_0          = 'HTTP/1.0'.freeze
    REMOTE_ADDR       = 'REMOTE_ADDR'.freeze
    CONTENT_LENGTH    = 'CONTENT_LENGTH'.freeze
    CONNECTION        = 'HTTP_CONNECTION'.freeze
    SCRIPT_NAME       = 'SCRIPT_NAME'.freeze
    KEEP_ALIVE_REGEXP = /\bkeep-alive\b/i.freeze
    CLOSE_REGEXP      = /\bclose\b/i.freeze
    HTTP              = 'http'.freeze
    EMPTY             = ''.freeze
    
    # Freeze some Rack header names
    RACK_INPUT        = 'rack.input'.freeze
    RACK_VERSION      = 'rack.version'.freeze
    RACK_ERRORS       = 'rack.errors'.freeze
    RACK_URL_SCHEME   = 'rack.url_scheme'.freeze
    RACK_MULTITHREAD  = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE     = 'rack.run_once'.freeze
    ASYNC_CALLBACK    = 'async.callback'.freeze
    ASYNC_CLOSE       = 'async.close'.freeze
    
    # CGI-like request environment variables
    attr_reader :env
    
    # Request body
    attr_reader :body
    
    def initialize
      @body = StringIO.new(INITIAL_BODY)
      @env = {
        SERVER_SOFTWARE   => SERVER,
        SERVER_NAME       => LOCALHOST,
        SCRIPT_NAME       => EMPTY,

        # Rack stuff
        RACK_INPUT        => @body,
        RACK_URL_SCHEME   => HTTP,

        RACK_VERSION      => VERSION::RACK,
        RACK_ERRORS       => $stderr,

        RACK_MULTITHREAD  => false,
        RACK_MULTIPROCESS => true,
        RACK_RUN_ONCE     => false
      }
    end
    
    def headers=(headers)
      headers.each_pair do |k, v|
        # Convert to Rack headers
        if k == 'Content-Type'
          @env["CONTENT_TYPE"] = v
        else
          @env["HTTP_" + k.upcase.tr("-", "_")] = v
        end
      end
      
      host, port = @env["HTTP_HOST"].split(":") if @env.key?("HTTP_HOST")
      @env['SERVER_NAME'] = host || "localhost"
      @env['SERVER_PORT'] = port || "80"
    end
    
    def method=(method)
      @env["REQUEST_METHOD"] = method
    end
    
    def path=(path)
      @env["PATH_INFO"] = path
    end
    
    def query_string=(string)
      @env["QUERY_STRING"] = string
    end
    
    def fragment=(string)
      @env["FRAGMENT"] = string
    end
    
    def <<(data)
      # TODO move to tempfile if too big
      @body << data
    end
    
    def close
      # TODO close tempfile if some
    end
  end
end