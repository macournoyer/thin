module Thin
  # A response sent to the client.
  class Response
    CONNECTION = 'Connection'.freeze
    CLOSE = 'close'.freeze
    
    attr_accessor :status, :file
    attr_reader   :body, :headers
    
    def initialize
      @headers = Headers.new
      @body    = StringIO.new
      @status  = 200
    end
    
    def headers_output
      @headers[CONTENT_LENGTH] = @body.size
      @headers[CONNECTION] = CLOSE
      @headers.to_s
    end
    
    def head
      "HTTP/1.1 #{@status} #{HTTP_STATUS_CODES[@status.to_i]}\r\n#{headers_output}\r\n"
    end
    
    def headers=(key_value_pairs)
      key_value_pairs.each do |k, vs|
        vs.each do |v|
          @headers[k] = v
        end
      end
    end
    
    def body=(stream)
      stream.each do |part|
        @body << part
      end
    end
    
    def close
      @body.close
    end
    
    def to_s
      @body.rewind
      head + @body.read
    end
  end
end