require "rack"

module Thin
  # A response sent to the client.
  class Response
    # Template async response.
    ASYNC = [-1, {}, []].freeze

    CONNECTION     = 'Connection'.freeze
    CLOSE          = 'close'.freeze
    KEEP_ALIVE     = 'keep-alive'.freeze
    SERVER         = 'Server'.freeze
    CONTENT_LENGTH = 'Content-Length'.freeze
    TRANSFER_ENCODING = 'Transfer-Encoding'.freeze
    CHUNKED = 'chunked'.freeze
    TERM = "\r\n".freeze
    COLON             = ':'.freeze
    
    KEEP_ALIVE_STATUSES = [100, 101].freeze
    
    STOCK_HTTP_10_OK_HEAD = "HTTP/1.0 200 OK\r\n".freeze
    STOCK_HTTP_11_OK_HEAD = "HTTP/1.1 200 OK\r\n".freeze
    

    # Status code
    attr_accessor :status

    # Response body, must respond to +each+.
    attr_accessor :body

    # Headers key-value hash
    attr_accessor :headers
    
    attr_reader :http_version

    def initialize(status=200, headers={}, body=[])
      @status = status
      @headers = Rack::Utils::HeaderHash.new(headers)
      @body = body
      @keep_alive = false
      @http_version = "HTTP/1.1"
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
      
      headers = ""
      @headers.each_pair do |key, values|
        next unless values
        values.split("\n").each { |value| headers << "#{key}#{COLON} #{value}#{TERM}" }
      end
      
      head + headers + TERM
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
      @body.each { |chunk| yield chunk }
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
