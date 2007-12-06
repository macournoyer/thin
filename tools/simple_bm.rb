require 'rubygems'
require 'eventmachine'
require 'fastthread'
require 'socket'

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
  EventMachine::start_server "0.0.0.0", 8081, EventWebServer
}

class ThreadWebServer
  @@count = 0
  
  def initialize(host, port)
    @socket = TCPServer.new(host, port)
    
    while true
      client = @socket.accept
      Thread.new do
        data = ''
        until data[0] == ?\r
          data = client.gets("\n")
        end
        receive_data(client)
        client.close
      end
    end
  end
  
  def receive_data(client)
    @@count += 1
    puts "#{@@count} requests" if @@count % 100 == 0
    client << "HTTP/1.1 200 OK\r\nConnection: close\r\nServer: Event\r\nContent-Type: text/html\r\n\r\n<html><h1>It works</h1></html>"
  end
end

# ThreadWebServer.new('0.0.0.0', 8081)