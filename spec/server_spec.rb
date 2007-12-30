require File.dirname(__FILE__) + '/spec_helper'
require 'net/http'
require 'socket'

describe Server do
  before do
    app = proc do |env|
      body = [env['QUERY_STRING'], env['rack.input'].read].compact
      [200, { 'Content-Type' => 'text/html' }, body]
    end
    server = Thin::Server.new('0.0.0.0', 3333, app)
    server.timeout = 3
    server.silent = true
    
    server.start
    @thread = Thread.new do
      server.listen!
    end
    sleep 0.1 until @thread.status == 'sleep'
  end
    
  it 'should GET from Net::HTTP' do
    get('/?cthis').should == 'cthis'
  end
  
  it 'should GET from TCPSocket' do
    raw('0.0.0.0', 3333, "GET /?this HTTP/1.1\r\n\r\n").should == "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 4\r\nConnection: close\r\n\r\nthis"
  end
  
  it 'should return empty string on incomplete headers' do
    raw('0.0.0.0', 3333, "GET /?this HTTP/1.1\r\nHost:").should be_empty
  end
  
  it 'should return empty string on incorrect Content-Length' do
    raw('0.0.0.0', 3333, "POST / HTTP/1.1\r\nContent-Length: 300\r\n\r\naye").should be_empty
  end
  
  it 'should POST from Net::HTTP' do
    post('/', :arg => 'pirate').should == 'arg=pirate'
  end
  
  it 'should handle big POST' do
    big = 'X' * (20 * 1024)
    post('/', :big => big).size.should == big.size + 4
  end
  
  it "should handle GET in less then #{get_request_time = 5} ms" do
    proc { get('/') }.should be_faster_then(get_request_time)
  end
  
  it "should handle POST in less then #{post_request_time = 6} ms" do
    proc { post('/', :file => 'X' * 1000) }.should be_faster_then(get_request_time)
  end
  
  after do
    @thread.kill
  end
  
  private
    def get(url)
      Net::HTTP.get(URI.parse('http://0.0.0.0:3333' + url))
    end
    
    def raw(host, port, data)
      socket = TCPSocket.new(host, port)
      socket.write data
      out = socket.read
      socket.close
      out
    end
    
    def post(url, params={})
      Net::HTTP.post_form(URI.parse('http://0.0.0.0:3333' + url), params).body
    end
end