require "stringio"

module Thin
  class Request
    attr_reader :env, :body
    
    def initialize
      @body = StringIO.new('')
      @env = {
        'rack.input' => @body
      }
    end
    
    def headers=(headers)
      headers.each_pair do |k, v|
        # Convert to Rack headers
        @env[k.upcase.tr("-", "_")] = v
      end
    end
    
    def <<(data)
      # TODO move to tempfile if too big
      @body << data
    end
    
    def close
      # TODO close tempfile if some
    end
  end
end