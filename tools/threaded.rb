require 'rubygems'
require 'fastthread'
require 'socket'

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
    sleep 100 if @@count % 10 == 0
    client << "HTTP/1.1 200 OK\r\nConnection: close\r\nServer: Event\r\nContent-Type: text/html\r\n\r\n<html><h1>It works</h1></html>"
  end
end

ThreadWebServer.new('0.0.0.0', 3000)