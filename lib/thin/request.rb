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
    %w[
      CONTENT_LENGTH
      GATEWAY_INTERFACE
      HTTP_HOST
      HTTP_VERSION
      PATH_INFO
      QUERY_STRING
      REMOTE_ADDR
      REQUEST_METHOD
      REQUEST_PATH
      REQUEST_URI
      SCRIPT_NAME
      SERVER_NAME
      SERVER_PORT
      SERVER_PROTOCOL
      SERVER_SOFTWARE
    ].each do |const|
      const_set(const, const.freeze)
    end

    HTTP_1_0          = 'HTTP/1.0'.freeze
    CONNECTION        = 'HTTP_CONNECTION'.freeze
    LOCALHOST         = 'localhost'.freeze
    KEEP_ALIVE_REGEXP = /\bkeep-alive\b/i.freeze
    CLOSE_REGEXP      = /\bclose\b/i.freeze

    # Freeze some Rack header names
    RACK_INPUT        = 'rack.input'.freeze
    RACK_VERSION      = 'rack.version'.freeze
    RACK_ERRORS       = 'rack.errors'.freeze
    RACK_MULTITHREAD  = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE     = 'rack.run_once'.freeze
    RACK_URL_SCHEME   = 'rack.url_scheme'.freeze
    ASYNC_CALLBACK    = 'async.callback'.freeze
    ASYNC_CLOSE       = 'async.close'.freeze

    # CGI-like request environment variables
    attr_reader :env

    # Unparsed data of the request
    attr_reader :data

    # Request body
    attr_reader :body

    def initialize
      @parser   = HTTP::Parser.new
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
        RACK_RUN_ONCE     => false,
        CONNECTION        => ''
      }
    end

    protected

    def on_headers_complete(headers)
      if (content_length = headers.delete('Content-Length'))
        @env[CONTENT_LENGTH] = content_length

        # Transfert to a tempfile if body is very big
        move_body_to_tempfile if content_length.to_i > MAX_BODY
      end

      @env[GATEWAY_INTERFACE] = 'CGI/1.2'
      @env[HTTP_VERSION] = @env[SERVER_PROTOCOL] = "HTTP/#{@parser.http_version.join('.')}"
      @env[REQUEST_METHOD] = @parser.http_method
      @env[QUERY_STRING] = @parser.query_string
      @env[PATH_INFO] = @env[REQUEST_PATH] = @parser.request_path
      @env[REQUEST_URI] = @parser.request_url
      @env[SCRIPT_NAME] = ''

      host = headers.delete('Host')
      @env[HTTP_HOST] = host if host
      @env[SERVER_PORT] = host.to_s.split(':', 2)[1] || '80'

      @env[RACK_URL_SCHEME] = 'http' # TODO

=begin
      keep_alive?
      upgrade?
      status_code
      request_url
      request_path
      fragment
      upgrade_data
      header_value_type = :mixed | :arrays | :strings
      reset!
=end

      # Convert back all the other headers to rack-compatible
      # TODO: verify if header_value_type == :mixed is the right-one
      headers.each_pair do |key, value|
        @env["HTTP_#{key.gsub('-', '_').upcase}"] = value
      end
    end

    def on_body(chunk)
      @body << chunk
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
      @finished
    rescue HTTP::Parser::Error => ex
      # re-raise as thin's error
      raise InvalidRequest, ex
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
