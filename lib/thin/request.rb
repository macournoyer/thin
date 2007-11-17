module Thin
  class InvalidRequest < StandardError; end
  
  class Request
    HTTP_LESS_HEADERS = %w(Content-Lenght Content-Type).freeze
    
    attr_reader :body, :params, :verb, :path
    
    def initialize(content)
      @params = {
        'GATEWAY_INTERFACE' => 'CGI/1.2',
        'HTTP_VERSION'      => 'HTTP/1.1'
      }
      parse! StringIO.new(content)
    end
    
    # Parse env variables according to:
    #   http://www.ietf.org/rfc/rfc3875
    def parse!(content)
      if matches = content.readline.match(/^([A-Z]+) (.*) HTTP/)
        @verb, uri = matches[1,2]
      else
        raise InvalidRequest, 'No valid header found'
      end

      raise InvalidRequest, "No method specified" unless @verb
      raise InvalidRequest, "No URI specified"    unless uri

      if matches = uri.match(/^(.*?)(?:\?(.*))?$/)
        @path, query_string = matches[1,2]
      else
        raise InvalidRequest, "No valid path found in #{uri}"
      end

      @params['REQUEST_URI']    = uri
      @params['REQUEST_PATH']   =
      @params['PATH_INFO']      = @path
      @params['SCRIPT_NAME']    = '/'
      @params['REQUEST_METHOD'] = @verb
      @params['QUERY_STRING']   = query_string if query_string
      
      headers = line = ''
      until [?\r, ?\n].include?(line[0]) || content.eof?
        headers << line = content.readline
      end
      
      params['CONTENT_TYPE']    = matches[1] if matches = headers.match(/^Content-Type: (.*)$/)
      params['CONTENT_LENGTH']  = matches[1] if matches = headers.match(/^Content-Length: (.*)$/)
      headers.grep(/^([A-za-z\-]+): (.*)$/) do
        name, value = $~[1,2]
        break if HTTP_LESS_HEADERS.include?(name)
        params["HTTP_#{name.upcase.gsub('-', '_')}"] = value.chomp
      end
      
      @params['SERVER_NAME']    = @params['HTTP_HOST'].split(':')[0] if @params['HTTP_HOST']
      
      @params['RAW_POST_DATA']  = content.read unless content.eof?
      
      @body = StringIO.new(@params['RAW_POST_DATA'].to_s)
    rescue InvalidRequest => e
      raise
    rescue Object => e
      raise InvalidRequest, e.message
    end
    
    def close
      @body.close
    end
    
    def to_s
      @body.rewind
      @body.readline
    end
  end
end