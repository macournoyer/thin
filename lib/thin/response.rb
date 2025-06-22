module Thin
  # A response sent to the client.
  class Response
    class Stream
      def initialize(writer)
        @read_closed = true
        @write_closed = false
        @writer = writer
      end

      def read(length = nil, outbuf = nil)
        raise ::IOError, 'not opened for reading' if @read_closed
      end

      def write(chunk)
        raise ::IOError, 'not opened for writing' if @write_closed

        @writer.call(chunk)
      end

      alias :<< :write

      def close
        @read_closed = @write_closed = true

        nil
      end

      def closed?
        @read_closed && @write_closed
      end

      def close_read
        @read_closed = true

        nil
      end

      def close_write
        @write_closed = true

        nil
      end

      def flush
        self
      end
    end

    CONNECTION     = 'connection'.freeze
    CLOSE          = 'close'.freeze
    KEEP_ALIVE     = 'keep-alive'.freeze
    SERVER         = 'server'.freeze
    CONTENT_LENGTH = 'content-length'.freeze

    PERSISTENT_STATUSES  = [100, 101].freeze

    #Error Responses
    ERROR            = [500, {'content-type' => 'text/plain'}, ['Internal server error']].freeze
    PERSISTENT_ERROR = [500, {'content-type' => 'text/plain', 'connection' => 'keep-alive', 'content-length' => "21"}, ['Internal server error']].freeze
    BAD_REQUEST      = [400, {'content-type' => 'text/plain'}, ['Bad Request']].freeze

    # Status code
    attr_accessor :status

    # Response body, must respond to +each+.
    attr_accessor :body

    # Headers key-value hash
    attr_reader   :headers

    def initialize
      @headers    = Headers.new
      @status     = 200
      @persistent = false
      @skip_body  = false
    end

    # String representation of the headers
    # to be sent in the response.
    def headers_output
      # Set default headers
      @headers[CONNECTION] = persistent? ? KEEP_ALIVE : CLOSE unless @headers.has_key?(CONNECTION)
      @headers[SERVER]     = Thin::NAME unless @headers.has_key?(SERVER)

      @headers.to_s
    end

    # Top header of the response,
    # containing the status code and response headers.
    def head
      "HTTP/1.1 #{@status} #{HTTP_STATUS_CODES[@status.to_i]}\r\n#{headers_output}\r\n"
    end

    def headers=(key_value_pairs)
      key_value_pairs.each do |k, vs|
        next unless vs
        if vs.is_a?(String)
          vs.each_line { |v| @headers[k] = v.chomp }
        else
          vs.each { |v| @headers[k] = v.chomp }
        end
      end if key_value_pairs
    end

    # Close any resource used by the response
    def close
      @body.close if @body.respond_to?(:close)
    end

    # Yields each chunk of the response.
    # To control the size of each chunk
    # define your own +each+ method on +body+.
    def each(&block)
      yield head

      unless @skip_body
        if @body.is_a?(String)
          yield @body
        elsif @body.respond_to?(:each)
          @body.each { |chunk| yield chunk }
        else
          @body.call(Stream.new(block))
        end
      end
    end

    # Tell the client the connection should stay open
    def persistent!
      @persistent = true
    end

    # Persistent connection must be requested as keep-alive
    # from the server and have a content-length, or the response
    # status must require that the connection remain open.
    def persistent?
      (@persistent && @headers.has_key?(CONTENT_LENGTH)) || PERSISTENT_STATUSES.include?(@status)
    end

    def skip_body!
      @skip_body = true
    end
  end
end
