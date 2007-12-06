require 'rubygems'
require 'eventmachine'
require "#{File.dirname(__FILE__)}/../lib/thin"

module RailsServer
  @@handlers = Thin::RailsHandler.new('../refactormycode'), Thin::DirHandler.new('../refactormycode/public')
  
  @@handlers.each { |h| h.start }
  
  def receive_data(data)
    request  = Thin::Request.new
    response = Thin::Response.new
    
    request.parse! StringIO.new(data)
    
    served = false
    @@handlers.each do |handler|
      served = handler.process(request, response)
      break if served
    end
    
    if served
      out = StringIO.new
      response.write out
      out.rewind
      send_data out.read
    else
      send_data Thin::ERROR_404_RESPONSE
    end
    
    close_connection_after_writing
  end
end

EventMachine::run {
  EventMachine::start_server "0.0.0.0", 3000, RailsServer
}
