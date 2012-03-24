require 'tempfile'
require 'http_parser'

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
    
    INITIAL_BODY      = ''
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
    KEEP_ALIVE_REGEXP = /\bkeep-alive\b/i.freeze
    CLOSE_REGEXP      = /\bclose\b/i.freeze
    
    # Freeze some Rack header names
    RACK_INPUT        = 'rack.input'.freeze
    RACK_VERSION      = 'rack.version'.freeze
    RACK_ERRORS       = 'rack.errors'.freeze
    RACK_MULTITHREAD  = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE     = 'rack.run_once'.freeze
    ASYNC_CALLBACK    = 'async.callback'.freeze
    ASYNC_CLOSE       = 'async.close'.freeze

    # CGI-like request environment variables
    attr_reader :env

    # Unparsed data of the request
    attr_reader :data

    # Request body
    attr_reader :body

    def initialize
      @parser   = HTTP::RequestParser.new
      @parser.on_headers_complete = method(:on_headers_complete)
      @parser.on_body = method(:on_body)
      @parser.on_message_begin = method(:on_message_begin)
      @parser.on_message_complete = method(:on_message_complete)

      @data     = ''
      @nparsed  = 0
      @body     = StringIO.new(INITIAL_BODY.dup)
      @env      = {
        SERVER_SOFTWARE   => SERVER,
        SERVER_NAME       => LOCALHOST,

        # Rack stuff
        RACK_INPUT        => @body,

        RACK_VERSION      => VERSION::RACK,
        RACK_ERRORS       => STDERR,

        RACK_MULTITHREAD  => false,
        RACK_MULTIPROCESS => false,
        RACK_RUN_ONCE     => false
      }
    end

    protected

    def on_headers_complete(headers)
      # TODO: adjust the keys there
      headers.each_pair do |key, value|
        @env["HTTP_#{key.upcase}"] = value
      end
      # TODO: http_version ?? method ? query_string ?

      content_length = headers['Content-Length'].to_i

      # Transfert to a tempfile if body is very big
      move_body_to_tempfile if content_length > MAX_BODY
    end

    def on_body(*a)
      p [:body, *a]
    end

    def on_message_begin
      @finished = false
      @data = ''
    end

    def on_message_complete
      @finished = true
      @data = nil
      @body.rewind
    end

    public

    # Parse a chunk of data into the request environment
    # Raises a +InvalidRequest+ if invalid.
    # Returns +true+ if the parsing is complete.
    def parse(data)
      @parser << data
      # TODO: re-raise with Thin's own error
      # TODO: raise InvalidRequest, 'Header longer than allowed' if @data.size > MAX_HEADER
      @finished
    end

    # +true+ if headers and body are finished parsing
    def finished?
      @finished
    end

    # Expected size of the body
    def content_length
      @env[CONTENT_LENGTH].to_i
    end

    # Returns +true+ if the client expect the connection to be persistent.
    def persistent?
      # Clients and servers SHOULD NOT assume that a persistent connection
      # is maintained for HTTP versions less than 1.1 unless it is explicitly
      # signaled. (http://www.w3.org/Protocols/rfc2616/rfc2616-sec8.html)
      if @env[HTTP_VERSION] == HTTP_1_0
        @env[CONNECTION] =~ KEEP_ALIVE_REGEXP

      # HTTP/1.1 client intends to maintain a persistent connection unless
      # a Connection header including the connection-token "close" was sent
      # in the request
      else
        @env[CONNECTION].nil? || @env[CONNECTION] !~ CLOSE_REGEXP
      end
    end

    def remote_address=(address)
      @env[REMOTE_ADDR] = address
    end

    def threaded=(value)
      @env[RACK_MULTITHREAD] = value
    end

    def async_callback=(callback)
      @env[ASYNC_CALLBACK] = callback
      @env[ASYNC_CLOSE] = EventMachine::DefaultDeferrable.new
    end

    def async_close
      @async_close ||= @env[ASYNC_CLOSE]
    end

    # Close any resource used by the request
    def close
      @body.delete if @body.class == Tempfile
    end

    private
      def move_body_to_tempfile
        current_body = @body
        current_body.rewind
        @body = Tempfile.new(BODY_TMPFILE)
        @body.binmode
        @body << current_body.read
        @env[RACK_INPUT] = @body
      end
  end
end
