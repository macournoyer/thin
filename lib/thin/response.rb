module Thin
  # A response sent to the client.
  class Response
    CONNECTION     = 'Connection'.freeze
    CLOSE          = 'close'.freeze
    KEEP_ALIVE     = 'keep-alive'.freeze
    SERVER         = 'Server'.freeze
    CONTENT_LENGTH = 'Content-Length'.freeze
    
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
    end
    
    # String representation of the headers
    # to be sent in the response.
    def headers_output
      # Set default headers
      @headers[CONNECTION] = persistent? ? KEEP_ALIVE : CLOSE
      @headers[SERVER]     = Thin::SERVER
      
      @headers.to_s
    end
        
    # Top header of the response,
    # containing the status code and response headers.
    def head
      "HTTP/1.1 #{@status} #{HTTP_STATUS_CODES[@status.to_i]}\r\n#{headers_output}\r\n"
    end
    
    def headers=(key_value_pairs)
      key_value_pairs.each do |k, vs|
        vs.each_line { |v| @headers[k] = v.chomp }
      end
    end
    
    # Close any resource used by the response
    def close
      @body.close if @body.respond_to?(:close)
    end
    
    # Yields each chunk of the response.
    # To control the size of each chunk
    # define your own +each+ method on +body+.
    def each
      yield head
      @body.each do |chunk|
        yield chunk
      end
    end
    
    # Tell the client the connection should stay open
    def persistent!
      @persistent = true
    end
    
    # Persistent connection must be requested as keep-alive
    # from the server and have a Content-Length.
    def persistent?
      @persistent && @headers.has_key?(CONTENT_LENGTH)
    end    
  end
end