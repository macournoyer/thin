module Thin
  class Response
    attr_accessor :headers, :status, :body
    
    def finish
      @headers["Connection"] = "close"
      @headers["Server"] = Thin::SERVER
    end
    
    def head
      headers_output = @headers.map { |k, v| "#{k}: #{v}\r\n" }.join
      "HTTP/1.1 #{status} OK\r\n#{headers_output}\r\n"
    end
    
    def each
      yield head
      @body.each { |chunk| yield chunk }
    end
  end
end