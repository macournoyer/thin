module Thin
  # Raised when an incoming request is not valid
  # and the server can not process it.
  class InvalidRequest < StandardError; end
  
  # A request made to the server.
  class Request
    class Params < Hash
      attr_accessor :http_body
    end

    attr_reader :params, :data, :body
    
    class << self
      attr_accessor :parser
      begin
        require 'http11'
        @@parser = Mongrel::HttpParser
      rescue
        raise LoadError, 'No parser available, install mongrel'
      end
    end
    
    def initialize
      @params   = Params.new
      @parser   = @@parser.new
      @data     = ''
      @nparsed  = 0
    end
    
    def parse(data)
      @data << data
			@nparsed = @parser.execute(@params, @data, @nparsed) unless @parser.finished?
			
			if @parser.finished?
			  if @body
          @body << data
  			else
  			  @body = StringIO.new
  			end
  			if @body.size >= content_length
			    @body.rewind
			    return true
			  end
			elsif @data.size > MAX_HEADER
			  raise InvalidRequest, 'Header longer than allowed'
			end
			
			false # Not finished
    rescue InvalidRequest => e
      raise e
    rescue Exception => e
      raise InvalidRequest, e.message
    end
    
    def close
      @body.close
    end
    
    def verb
      @params['REQUEST_METHOD']
    end
    
    def content_length
      @params['CONTENT_LENGTH'].to_i
    end
    
    def path
      @params['REQUEST_PATH']
    end
    
    def to_s
      "#{verb} #{path}"
    end
  end
end