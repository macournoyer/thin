require "rack"

module Thin
  # A response sent to the client.
  class Response
    # Template async response.
    ASYNC = [-1, {}, []].freeze
    
    # Store HTTP header name-value pairs direcly to a string
    # and allow duplicated entries on some names.
    class Headers
      HEADER_FORMAT      = "%s: %s\r\n".freeze
      ALLOWED_DUPLICATES = %w(Set-Cookie Set-Cookie2 Warning WWW-Authenticate).freeze

      def initialize
        @sent = {}
        @out = []
      end

      # Add <tt>key: value</tt> pair to the headers.
      # Ignore if already sent and no duplicates are allowed
      # for this +key+.
      def []=(key, value)
        if !@sent.has_key?(key) || ALLOWED_DUPLICATES.include?(key)
          @sent[key] = true
          value = case value
                  when Time
                    value.httpdate
                  when NilClass
                    return
                  else
                    value.to_s
                  end
          @out << HEADER_FORMAT % [key, value]
        end
      end

      def has_key?(key)
        @sent[key]
      end

      def to_s
        @out.join
      end
    end

    CONNECTION     = 'Connection'.freeze
    CLOSE          = 'close'.freeze
    KEEP_ALIVE     = 'keep-alive'.freeze
    SERVER         = 'Server'.freeze
    CONTENT_LENGTH = 'Content-Length'.freeze
    TRANSFER_ENCODING = 'Transfer-Encoding'.freeze
    CHUNKED = 'chunked'.freeze
    TERM = "\r\n".freeze
    
    KEEP_ALIVE_STATUSES = [100, 101].freeze
    
    STOCK_HTTP_10_OK_HEAD = "HTTP/1.0 200 OK\r\n".freeze
    STOCK_HTTP_11_OK_HEAD = "HTTP/1.1 200 OK\r\n".freeze
    

    # Status code
    attr_accessor :status

    # Response body, must respond to +each+.
    attr_accessor :body

    # Headers key-value hash
    attr_reader :headers
    
    attr_reader :http_version

    def initialize(status=200, headers=nil, body=nil)
      @headers = Headers.new
      @status = status
      @keep_alive = false
      @body = body
      @http_version = "HTTP/1.1"

      self.headers = headers if headers
    end

    if System.ruby_18?

      # Ruby 1.8 implementation.
      # Respects Rack specs.
      #
      # See http://rack.rubyforge.org/doc/files/SPEC.html
      def headers=(key_value_pairs)
        key_value_pairs.each do |k, vs|
          vs.each { |v| @headers[k] = v.chomp } if vs
        end if key_value_pairs
      end

    else

      # Ruby 1.9 doesn't have a String#each anymore.
      # Rack spec doesn't take care of that yet, for now we just use
      # +each+ but fallback to +each_line+ on strings.
      # I wish we could remove that condition.
      # To be reviewed when a new Rack spec comes out.
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

    end

    # Finish preparing the response.
    def finish
      @headers[CONNECTION] = keep_alive? ? KEEP_ALIVE : CLOSE
      @headers[SERVER] = Thin::SERVER
    end

    # Top header of the response,
    # containing the status code and response headers.
    def head
      # Optimize for most common case, 200 OK.
      if @status == 200
        if http_10?
          head = STOCK_HTTP_10_OK_HEAD
        else
          head = STOCK_HTTP_11_OK_HEAD
        end
      else
        status_message = Rack::Utils::HTTP_STATUS_CODES[@status.to_i]
        head = "#{@http_version} #{@status} #{status_message}#{TERM}"
      end
      head + @headers.to_s + TERM
    end

    # Close any resource used by the response
    def close
      @body.fail if @body.respond_to?(:fail)
      @body.close if @body.respond_to?(:close)
    end

    # Yields each chunk of the response.
    # To control the size of each chunk
    # define your own +each+ method on +body+.
    def each
      yield head
      if @body.is_a?(String)
        yield @body
      else
        @body.each { |chunk| yield chunk }
      end
    end
    
    # Tell the client the connection should stay open
    def keep_alive!
      @keep_alive = true
    end

    # Keep-alive requests must be requested as keep-alive and MUST have a self-defined message length.
    # See http://www.w3.org/Protocols/rfc2616/rfc2616-sec8.html#sec8.1.2.1.
    def keep_alive?
      (@keep_alive && (@headers.has_key?(CONTENT_LENGTH) || chunked_encoding?)) ||
      KEEP_ALIVE_STATUSES.include?(@status)
    end

    def async?
      @status == ASYNC.first
    end
    
    def file?
      @body.respond_to?(:to_path)
    end
    
    def filename
      @body.to_path
    end
    
    def body_callback=(proc)
      @body.callback(&proc) if @body.respond_to?(:callback)
      @body.errback(&proc) if @body.respond_to?(:errback)
    end
    
    def chunked_encoding!
      @headers[TRANSFER_ENCODING] = CHUNKED
    end
    
    def chunked_encoding?
      @headers[TRANSFER_ENCODING] == CHUNKED
    end
    
    def http_version=(string)
      return unless string
      @http_version = string
    end
    
    def http_10?
      @http_version[7] == ?0
    end

    def http_11?
      @http_version[7] == ?1
    end

    def self.error(status=500, message=Rack::Utils::HTTP_STATUS_CODES[status])
      new status,
          { "Content-Type" => "text/plain",
            "Content-Length" => Rack::Utils.bytesize(message).to_s },
          [message]
    end
  end
end
