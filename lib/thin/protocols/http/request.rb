require "stringio"
require "tempfile"

module Thin
  module Protocols
    class Http
      # A request sent by the client to the server.
      class Request
        # Maximum request body size before it is moved out of memory
        # and into a tempfile for reading.
        MAX_BODY          = 1024 * (80 + 32)
        BODY_TMPFILE      = 'thin-body'.freeze

        INITIAL_BODY = ''
        # Force external_encoding of request's body to ASCII_8BIT
        INITIAL_BODY.encode!(Encoding::ASCII_8BIT) if INITIAL_BODY.respond_to?(:encode!)

        # Freeze some HTTP header names & values
        SERVER_SOFTWARE   = 'SERVER_SOFTWARE'.freeze
        SERVER_NAME       = 'SERVER_NAME'.freeze
        SERVER_PORT       = 'SERVER_PORT'.freeze
        DEFAULT_PORT      = '80'.freeze
        HTTP_HOST         = 'HTTP_HOST'.freeze
        LOCALHOST         = 'localhost'.freeze
        HTTP_VERSION      = 'HTTP_VERSION'.freeze
        SERVER_PROTOCOL   = 'SERVER_PROTOCOL'.freeze
        HTTP_1_0          = 'HTTP/1.0'.freeze
        REMOTE_ADDR       = 'REMOTE_ADDR'.freeze
        CONTENT_TYPE      = 'CONTENT_TYPE'.freeze
        CONTENT_TYPE_L    = 'Content-Type'.freeze
        CONTENT_LENGTH    = 'CONTENT_LENGTH'.freeze
        CONTENT_LENGTH_L  = 'Content-Length'.freeze
        SCRIPT_NAME       = 'SCRIPT_NAME'.freeze
        QUERY_STRING      = 'QUERY_STRING'.freeze
        PATH_INFO         = 'PATH_INFO'.freeze
        REQUEST_METHOD    = 'REQUEST_METHOD'.freeze
        FRAGMENT          = 'FRAGMENT'.freeze
        HTTP              = 'http'.freeze
        EMPTY             = ''.freeze
        KEEP_ALIVE_REGEXP = /\bkeep-alive\b/i.freeze
        CLOSE_REGEXP      = /\bclose\b/i.freeze

        # Freeze some Rack header names
        RACK_INPUT        = 'rack.input'.freeze
        RACK_VERSION      = 'rack.version'.freeze
        RACK_ERRORS       = 'rack.errors'.freeze
        RACK_URL_SCHEME   = 'rack.url_scheme'.freeze
        RACK_MULTITHREAD  = 'rack.multithread'.freeze
        RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
        RACK_RUN_ONCE     = 'rack.run_once'.freeze
        ASYNC_CALLBACK    = 'async.callback'.freeze

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

            RACK_RUN_ONCE     => false
          }
          @keep_alive = false
        end

        def headers=(headers)
          # TODO benchmark & optimize
          headers.each_pair do |k, v|
            # Convert to Rack headers
            if k == CONTENT_TYPE_L
              @env[CONTENT_TYPE] = v
            elsif k == CONTENT_LENGTH_L
              @env[CONTENT_LENGTH] = v
            else
              @env["HTTP_" + k.upcase.tr("-", "_")] = v
            end
          end

          host, port = @env[HTTP_HOST].split(":") if @env.key?(HTTP_HOST)
          @env[SERVER_NAME] = host || LOCALHOST
          @env[SERVER_PORT] = port || DEFAULT_PORT
        end

        # Expected size of the body
        def content_length
          @env[CONTENT_LENGTH].to_i
        end

        def remote_address=(address)
          @env[REMOTE_ADDR] = address
        end

        def method=(method)
          @env[REQUEST_METHOD] = method
        end

        def http_version=(string)
          @env[HTTP_VERSION] = string
          @env[SERVER_PROTOCOL] = string
        end
        
        def http_version
          @env[HTTP_VERSION]
        end

        def path=(path)
          @env[PATH_INFO] = path
        end

        def query_string=(string)
          @env[QUERY_STRING] = string
        end

        def fragment=(string)
          @env[FRAGMENT] = string
        end
        
        def keep_alive=(bool)
          @keep_alive = bool
        end
        
        def multithread=(bool)
          @env[RACK_MULTITHREAD] = bool
        end
        
        def multiprocess=(bool)
          @env[RACK_MULTIPROCESS] = bool
        end
        
        # Returns +true+ if the client expect the connection to be kept alive.
        def keep_alive?
          @keep_alive
        end

        def <<(data)
          @body << data

          # Transfert to a tempfile if body is very big.
          move_body_to_tempfile if content_length > MAX_BODY

          @body
        end

        def async_callback=(callback)
          @env[ASYNC_CALLBACK] = callback
        end
        
        def support_encoding_chunked?
          @env[HTTP_VERSION] != HTTP_1_0
        end

        # Called when we're done processing the request.
        def finish
          @body.rewind
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
  end
end
