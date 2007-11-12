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
        verb, uri = matches[1,2]
      else
        raise InvalidRequest, 'No valid header found'
      end

      raise InvalidRequest, "No method specified" unless verb
      raise InvalidRequest, "No URI specified" unless uri

      if matches = uri.match(/^(.*?)(?:\?(.*))?$/)
        @path, query_string = matches[1,2]
      else
        raise InvalidRequest, "No valid path found in #{uri}"
      end
      
      raise InvalidRequest, "Invalid path specified : #{uri}" unless @path
      
      @verb = verb.upcase

      @params['REQUEST_URI']    = uri
      @params['REQUEST_PATH']   = @path
      @params['SCRIPT_NAME']    = @path
      @params['QUERY_STRING']   = query_string
      @params['REQUEST_METHOD'] = @verb
      
      body = @body.read      
      extract_http_var body, params, 'Host', 'HTTP_HOST'
      extract_http_var body, params, CONTENT_TYPE, 'CONTENT_TYPE'
      extract_http_var body, params, CONTENT_LENGTH, 'CONTENT_LENGTH'
      extract_http_var body, params, 'Referer', 'HTTP_REFERER'
      extract_http_var body, params, 'User-Agent', 'HTTP_USER_AGENT'
      extract_http_var body, params, 'Accept-Language', 'HTTP_ACCEPT_LANGUAGE'
      extract_http_var body, params, 'Cookie', 'HTTP_COOKIE'
      
      if post_data = (body.split("\r\n"*2)[1] || body.split("\n"*2)[1])
        @params['RAW_POST_DATA'] = post_data
      end
    rescue Object => e
      raise InvalidRequest, e.message
    end
    
    def to_s
      @body.rewind
      @body.readline
    end
    
    protected
      def extract_http_var(body, params, header, var, required=false)
        if matches = body.match(/^#{header}: (.*)$/)
          params[var] = matches[1]
        elsif required
          raise InvalidRequest, "Required header #{header} is missing"
        end
      end
  end
end