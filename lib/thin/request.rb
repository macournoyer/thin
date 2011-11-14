require "stringio"

module Thin
  class Request
    attr_reader :headers, :body
    
    def initialize
      @headers = nil
      @body = ''
    end
    
    def headers=(headers)
      # Convert to Rack headers
      @headers = headers.inject({}) { |h, (k, v)| h[k.upcase.tr("-", "_")] = v; h }
    end
    
    def <<(chunk)
      # TODO move to file if too big
      @body << chunk
    end
    
    def to_env
      { "rack.input" => StringIO.new(@body) }.update(headers)
    end
  end
end