require 'stringio'

module Fart
  class Response
    CONNECTION = 'Connection'.freeze
    CLOSE = 'close'.freeze
    
    attr_accessor :body, :headers, :status
    
    def initialize
      @headers = {}
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
      @headers.inject('') { |out, (name, value)| out << "#{name}: #{value}\r\n" }
    end
    
    def head
      "HTTP/1.1 #{@status} #{HTTP_STATUS_CODES[@status.to_i]}\r\n#{headers_output}\r\n"
    end
    
    def write(socket)
      socket << head
      body.rewind
      socket << body.read
    end
    
    def start(status)
      @status = status
      yield @headers, @body
    end
    
    def to_s
      "#{@status} #{HTTP_STATUS_CODES[@status.to_i]}"
    end
  end
end