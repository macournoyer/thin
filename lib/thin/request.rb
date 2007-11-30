module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < StandardError; end
  
  # A request made to the server.
  class Request
    HTTP_LESS_HEADERS = %w(Content-Length Content-Type).freeze
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
    
    attr_reader :body, :params, :verb, :path
    
    def initialize(content)
      @params = {
        'GATEWAY_INTERFACE' => 'CGI/1.2',
        'HTTP_VERSION'      => 'HTTP/1.1',
        'SERVER_PROTOCOL'   => 'HTTP/1.1'
      }
      @body = StringIO.new

      parse_headers! content
      parse_body!    content if BODYFUL_METHODS.include?(verb)
    end
        
    # Parse the request headers from the socket into CGI like variables.
    # Parse the request according to http://www.w3.org/Protocols/rfc2616/rfc2616.html
    # Parse env variables according to http://www.ietf.org/rfc/rfc3875
    def parse_headers!(content)
      if matches = readline(content).match(/^([A-Z]+) (.*?)(?:#(.*))? HTTP/)
        @verb, uri, fragment = matches[1,3]
      else
        raise InvalidRequest, 'No valid header found'
      end
    
      raise InvalidRequest, 'No method specified' unless @verb
      raise InvalidRequest, 'No URI specified'    unless uri
    
      # Validation various length for security
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
    
      headers_size = 0
      until content.eof?
        line = readline(content)
        headers_size += line.size
        if [?\r, ?\n].include?(line[0])
          break # Reached the end of the headers
        elsif matches = line.match(/^([\w\-]+): (.*)$/)
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
    rescue InvalidRequest => e
      raise
    rescue Object => e
      raise InvalidRequest, e.message
    end
    
    def parse_body!(content)
      # Parse by chunks
      length = content_length
      while @body.size < length
        chunk = content.readpartial(CHUNK_SIZE)
        break unless chunk && chunk.size > 0
        @body << chunk
        break if chunk.size < CHUNK_SIZE
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
        begin
          io.gets(LF)
        rescue Errno::ECONNRESET
          nil
        end      
      end
  end
end