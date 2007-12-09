require 'rubygems'
require 'eventmachine'

module EventWebServer
  @@count = 0
  
  def receive_data data
    @@count += 1
    puts "#{@@count} requests" if @@count % 100 == 0
    send_data "HTTP/1.1 200 OK\r\nConnection: close\r\nServer: Event\r\nContent-Type: text/html\r\n\r\n<html><h1>It works</h1></html>"
    close_connection_after_writing
  end
end

EventMachine::run {
  EventMachine::start_server "0.0.0.0", 3000, EventWebServer
}