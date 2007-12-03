module Thin
  class RailsHandler < Handler
    def initialize(pwd, env='development')
      @env = env
      @pwd = pwd
    end
    
    def start
      ENV['RAILS_ENV'] = @env
      
      require "#{@pwd}/config/environment"
      require 'dispatcher'
    end
    
    def process(request, response)
      # Rails doesn't serve static files
      return false if File.file?(File.join(@pwd, 'public', request.path))
      
      cgi = CGIWrapper.new(request, response)
      
      Dispatcher.dispatch(cgi, ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS, response.body)
      
      # This finalizes the output using the proper HttpResponse way
      cgi.out("text/html", true) {""}
    end
    
    def to_s
      "Rails on #{@pwd} (env=#{@env})"
    end
  end
  
  class RailsServer < Server
    def initialize(address, port, environment='development')
      super address, port,
            # Let Rails handle his thing and ignore files
            Thin::RailsHandler.new('.', environment),
            # Serve static files
            Thin::DirHandler.new('public')
    end
  end
end