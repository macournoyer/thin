require File.dirname(__FILE__) + '/spec_helper'
require 'net/http'
require 'socket'

describe Server do
  before do
    app = proc do |env|
      body = ''
      body << env['QUERY_STRING'].to_s
      body << env['rack.input'].read.to_s
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => body.size.to_s }, body]
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
    raw('0.0.0.0', 3333, "GET /?this HTTP/1.1\r\n\r\n").
      should include("HTTP/1.1 200 OK",
                     "Content-Type: text/html", "Content-Length: 4",
                     "Connection: close", "\r\n\r\nthis")
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
  
  it "should handle GET in less then #{get_request_time = 0.004} RubySecond" do
    proc { get('/') }.should be_faster_then(get_request_time)
  end
  
  it "should handle POST in less then #{post_request_time = 0.007} RubySecond" do
    proc { post('/', :file => 'X' * 1000) }.should be_faster_then(post_request_time)
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

describe Server, 'app configuration' do
  it "should build app from constructor" do
    server = Server.new('0.0.0.0', 3000, :works)
    
    server.app.should == :works
  end
  
  it "should build app from builder block" do
    server = Server.new '0.0.0.0', 3000 do
      run(proc { |env| :works })
    end
    
    server.app.call({}).should == :works
  end
  
  it "should use middlewares in builder block" do
    server = Server.new '0.0.0.0', 3000 do
      use Rack::ShowExceptions
      run(proc { |env| :works })
    end
    
    server.app.class.should == Rack::ShowExceptions
    server.app.call({}).should == :works
  end
  
  it "should work with Rack url mapper" do
    server = Server.new '0.0.0.0', 3000 do
      map '/test' do
        run(proc { |env| :works })
      end
    end
    
    server.app.call({})[0].should == 404
    server.app.call({'PATH_INFO' => '/test'}).should == :works
  end
end