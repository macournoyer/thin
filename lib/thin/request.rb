require "stringio"

module Thin
  class Request
    attr_reader :env, :body
    
    INITIAL_BODY      = ''
    # Force external_encoding of request's body to ASCII_8BIT
    INITIAL_BODY.encode!(Encoding::ASCII_8BIT) if INITIAL_BODY.respond_to?(:encode!)
    
    def initialize
      @body = StringIO.new(INITIAL_BODY)
      @env = {
        'rack.input' => @body,
        'rack.errors' => $stderr,
        'rack.version' => VERSION::RACK,
        'rack.url_scheme' => 'http',
        'rack.multithread' => false,
        'rack.multiprocess' => true,
        'rack.run_once' => false,
        
        'SCRIPT_NAME' => ''
      }
    end
    
    def headers=(headers)
      headers.each_pair do |k, v|
        # Convert to Rack headers
        if k == 'Content-Type'
          @env["CONTENT_TYPE"] = v
        else
          @env["HTTP_" + k.upcase.tr("-", "_")] = v
        end
      end
      
      host, port = @env["HTTP_HOST"].split(":") if @env.key?("HTTP_HOST")
      @env['SERVER_NAME'] = host || "localhost"
      @env['SERVER_PORT'] = port || "80"
    end
    
    def method=(method)
      @env["REQUEST_METHOD"] = method
    end
    
    def path=(path)
      @env["PATH_INFO"] = path
    end
    
    def query_string=(string)
      @env["QUERY_STRING"] = string
    end
    
    def fragment=(string)
      @env["FRAGMENT"] = string
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