module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < StandardError; end
  
  # A request made to the server.
  class Request
    # HTTP headers that should not have a +HTTP_+ prefixed to the CGI variable name
    HTTP_LESS_HEADERS = %w(Content-Length Content-Type).freeze
    # Methods that might contain a body.
    BODYFUL_METHODS   = %w(POST PUT).freeze

    # We control max length of different part of the request
    # to prevent attack and resource overflow.
    MAX_FIELD_NAME_LENGTH   = 256
    MAX_FIELD_VALUE_LENGTH  = 80 * 1024
    MAX_REQUEST_URI_LENGTH  = 1024 * 12
    MAX_FRAGMENT_LENGTH     = 1024
    MAX_REQUEST_PATH_LENGTH = 1024
    MAX_QUERY_STRING_LENGTH = 1024 * 10
    MAX_HEADER_LENGTH       = 1024 * (80 + 32)
    
    attr_reader   :body, :params, :verb, :path

    # For debugging and trace.
    # When +trace+ is set to true, +raw+ will be populated with
    # the raw request.
    attr_accessor :trace, :raw
    
    def initialize
      @params = {
        'GATEWAY_INTERFACE' => CGI_VERSION,
        'HTTP_VERSION'      => HTTP_VERSION,
        'SERVER_PROTOCOL'   => HTTP_VERSION
      }
      @body = StringIO.new
      @raw = ''
      @trace = false
    end
    
    # Parse the headers and body from the +content+ buffer.
    def parse!(content)      
      parse_headers! content
      parse_body!    content if BODYFUL_METHODS.include?(verb)
    rescue InvalidRequest => e
      raise
    rescue Object => e
      raise InvalidRequest, e.message
    end
        
    # Parse the request headers from the socket into CGI like variables.
    # Parse the request according to http://www.w3.org/Protocols/rfc2616/rfc2616.html.
    # Parse env variables according to http://www.ietf.org/rfc/rfc3875.
    # Raises an InvalidRequest error when the request is not valid, because:
    # * no valid request line
    # * uri, path or header is too long
    def parse_headers!(content)
      if matches = readline(content).match(/^([A-Z]+) (.*?)(?:#(.*))? HTTP/)
        @verb, uri, fragment = matches[1,3]
      else
        raise InvalidRequest, 'No valid request line found'
      end
    
      raise InvalidRequest, 'No method specified' unless @verb
      raise InvalidRequest, 'No URI specified'    unless uri
    
      # Validate various length for security
      raise InvalidRequest, 'URI too long'        if uri.size > MAX_REQUEST_URI_LENGTH
      raise InvalidRequest, 'Fragment too long'   if fragment && fragment.size > MAX_FRAGMENT_LENGTH

      if matches = uri.match(/^(.*?)(?:\?(.*))?$/)
        @path, query_string = matches[1,2]
      else
        raise InvalidRequest, "No valid path found in #{uri}"
      end
    
      raise InvalidRequest, 'Request path too long' if @path.size > MAX_REQUEST_PATH_LENGTH
      raise InvalidRequest, 'Query string path too long' if query_string && query_string.size > MAX_QUERY_STRING_LENGTH

      @params['REQUEST_URI']    = uri
      @params['FRAGMENT']       = fragment if fragment
      @params['REQUEST_PATH']   =
      @params['PATH_INFO']      = @path
      @params['SCRIPT_NAME']    = '/'
      @params['REQUEST_METHOD'] = @verb
      @params['QUERY_STRING']   = query_string if query_string
    
      # Parse all headers from 'Something-Weird' into @params['HTTP_SOMETHING_WEIRD']
      headers_size = 0
      until content.eof?
        line = readline(content)
        headers_size += line.size
        
        break if ?\r == line[0] # Reached the end of the headers
        if matches = line.match(/^([\w\-]+): (.*)$/)
          name, value = matches[1,2]
          raise InvalidRequest, 'Header name too long' if name.size > MAX_FIELD_NAME_LENGTH
          raise InvalidRequest, 'Header value too long' if value.size > MAX_FIELD_VALUE_LENGTH
          # Transform headers into a HTTP_NAME => value hash
          prefix = HTTP_LESS_HEADERS.include?(name) ? '' : 'HTTP_'
          params["#{prefix}#{name.upcase.gsub('-', '_')}"] = value.chomp
        else
          raise InvalidRequest, "Expected header : #{line}"
        end
      end  

      raise InvalidRequest, 'Headers too long' if headers_size > MAX_HEADER_LENGTH
    
      @params['SERVER_NAME'] = @params['HTTP_HOST'].split(':')[0] if @params['HTTP_HOST']      
    end
    
    # Parse the request body by chunks.
    # We assume the Content-Length is valid and is the actual size of the body.
    # This is garanteed when used behind a proxy server like Nginx:
    #   Note that when using the HTTP Proxy Module (or even when using FastCGI), the entire client
    #   request will be buffered in nginx before being passed on to the backend proxied servers.
    #   As a result, upload progress meters will not function correctly if they work by measuring
    #   the data received by the backend servers.
    #   - http://wiki.codemongers.com/NginxHttpProxyModule
    # On Apache w/ mod_proxy, you need to install mod_accel : http://sysoev.ru/en/
    def parse_body!(content)
      length = content_length
      while @body.size < length
        chunk = content.readpartial(CHUNK_SIZE)
        break unless chunk && chunk.size > 0
        @body << chunk
      end
      
      @body.rewind
    end
    
    def close
      @body.close
    end
    
    def content_length
      @params['CONTENT_LENGTH'].to_i
    end
    
    def to_s
      "#{@params['REQUEST_METHOD']} #{@params['REQUEST_URI']}"
    end
    
    private
      def readline(io)
        out = io.gets(LF)
        @raw << out if @trace # Build a gigantic string to later print trace for the request
        out
      end
  end
end