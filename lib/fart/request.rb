require 'uri'

module Fart
  class InvalidRequest < StandardError; end
  
  class Request
    attr_reader :body, :params, :verb, :path
    
    def initialize(body)
      @body = StringIO.new(body)
      @params = {
        'GATEWAY_INTERFACE' => 'CGI/1.1',
        'SERVER_SOFTWARE'   => SERVER
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
      @params['SCRIPT_NAME']    = @path
      @params['QUERY_STRING']   = query_string
      @params['REQUEST_METHOD'] = @verb
      
      body = line = ''
      until [?\r, ?\n].include?(line[0]) || @body.eof?
        body << line = @body.readline
      end
      
      params['HTTP_HOST']       = matches[1] if matches = body.match(/^Host: (.*)$/)
      params['CONTENT_TYPE']    = matches[1] if matches = body.match(/^Content-Type: (.*)$/)
      params['CONTENT_LENGTH']  = matches[1] if matches = body.match(/^Content-Length: (.*)$/)
      params['HTTP_REFERER']    = matches[1] if matches = body.match(/^Referer: (.*)$/)
      params['HTTP_USER_AGENT'] = matches[1] if matches = body.match(/^User-Agent: (.*)$/)
      params['HTTP_COOKIE']     = matches[1] if matches = body.match(/^Cookie: (.*)$/)
      
      return if @body.eof?
      @params['RAW_POST_DATA'] = @body.read
    rescue Object => e
      raise InvalidRequest, e.message
    end
    
    def to_s
      @body.rewind
      @body.readline
    end
  end
end