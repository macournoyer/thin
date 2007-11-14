module Thin
  class RailsHandler < Handler
    def initialize(pwd, env='development')
      ENV['RAILS_ENV'] = env
      @pwd = pwd
      Object.const_set 'RAILS_DEFAULT_LOGGER', LOGGER
      
      require "#{@pwd}/config/environment"
      require 'dispatcher'
    end
    
    def process(request, response)
      # Rails doesn't serve static files
      return false if File.file?(File.join(@pwd, 'public', request.path))
      
      cgi = CGIWrapper.new(request, response)
      
      Dispatcher.dispatch(cgi, ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS, response.body)
      
      # This finalizes the output using the proper HttpResponse way
      cgi.out("text/html",true) {""}
    end
  end
end