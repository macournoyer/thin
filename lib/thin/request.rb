require 'uri'

module Thin
  class InvalidRequest < StandardError; end
  
  class Request
    HTTP_LESS_HEADERS = %w(Content-Lenght Content-Type).freeze
    
    attr_reader :body, :params, :verb, :path
    
    def initialize(body)
      @body = StringIO.new(body)
      @params = {
        'GATEWAY_INTERFACE' => 'CGI/1.1',
        'HTTP_VERSION'      => 'HTTP/1.1'
      }
      parse!
    end
    
    # Parse env variables according to:
    #   http://www.ietf.org/rfc/rfc3875
    def parse!
      @body.rewind
      
      if matches = @body.readline.match(/^([A-Z]+) (.*) HTTP/)
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
      @params['REQUEST_PATH']   = @path
      @params['REQUEST_METHOD'] = @verb
      @params['SCRIPT_NAME']    = @path
      @params['QUERY_STRING']   = query_string if query_string
      
      body = line = ''
      until [?\r, ?\n].include?(line[0]) || @body.eof?
        body << line = @body.readline
      end
      
      params['CONTENT_TYPE']    = matches[1] if matches = body.match(/^Content-Type: (.*)$/)
      params['CONTENT_LENGTH']  = matches[1] if matches = body.match(/^Content-Length: (.*)$/)
      body.grep(/^([A-za-z\-]+): (.*)$/) do
        name, value = $~[1,2]
        break if HTTP_LESS_HEADERS.include?(name)
        params["HTTP_#{name.upcase.gsub('-', '_')}"] = value.chomp
      end
      
      return if @body.eof?
      @params['RAW_POST_DATA'] = @body.read
    
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