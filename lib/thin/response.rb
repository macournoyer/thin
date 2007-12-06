module Thin
  # A response sent to the client.
  class Response
    CONNECTION = 'Connection'.freeze
    CLOSE = 'close'.freeze
    
    attr_accessor :body, :headers, :status, :file
    
    def initialize
      @headers = Headers.new
      @body = StringIO.new
      @status = 200
    end
    
    def content_type=(type)
      @headers[CONTENT_TYPE] = type
    end
    
    def content_type
      @headers[CONTENT_TYPE]
    end
    
    def headers_output
      @headers[CONTENT_LENGTH] = @body.size
      @headers[CONNECTION] = CLOSE
      @headers.to_s
    end
    
    def head
      "HTTP/1.1 #{@status} #{HTTP_STATUS_CODES[@status.to_i]}\r\n#{headers_output}\r\n"
    end
    
    def close
      @body.close
    end
    
    def start(status)
      @status = status
      yield @headers, @body
    end
    
    def send_data_to(connection)
      connection.send_data head
      @body.rewind
      connection.send_data @body.read 
    end
    
    def to_s
      @body.rewind
      head + @body.read
    end
  end
end