require File.dirname(__FILE__) + '/../spec_helper'

describe Server, "HTTP pipelining" do
  before do
    calls = 0
    start_server do |env|
      calls += 1
      body = env['PATH_INFO'] + '-' + calls.to_s
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => body.size.to_s }, body]
    end
  end
  
  it "should pipeline request on same socket" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write "GET /first HTTP/1.1\r\nConnection: keep-alive\r\n\r\n"
    socket.flush
    socket.write "GET /second HTTP/1.1\r\nConnection: close\r\n\r\n"
    response = socket.read
    socket.close
    
    response.should include('/first-1', '/second-2')
  end
  
  it "should pipeline requests by default on HTTP 1.1" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write "GET /first HTTP/1.1\r\n\r\n"
    socket.flush
    socket.write "GET /second HTTP/1.1\r\nConnection: close\r\n\r\n"
    response = socket.read
    socket.close
    
    response.should include('/first-1', '/second-2')
  end
  
  it "should not pipeline request by default on HTTP 1.0" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write "GET /first HTTP/1.0\r\n\r\n"
    socket.flush
    socket.write "GET /second HTTP/1.0\r\nConnection: close\r\n\r\n"
    response = socket.read
    socket.close
    
    response.should include('/first-1')
    response.should_not include('/second-2')
  end
  
  it "should not pipeline request on same socket when connection is closed" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write "GET /first HTTP/1.1\r\nConnection: close\r\n\r\n"
    socket.flush
    socket.write "GET /second HTTP/1.1\r\nConnection: close\r\n\r\n"
    response = socket.read
    socket.close
    
    response.should include('/first-1')
    response.should_not include('/second-2')
  end
  
  after do
    stop_server
  end
end