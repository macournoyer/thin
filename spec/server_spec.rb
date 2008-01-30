require File.dirname(__FILE__) + '/spec_helper'
require 'net/http'
require 'socket'

describe Server do
  before do
    app = proc do |env|
      body = ''
      body << env.inspect
      body << env['rack.input'].read
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => body.size.to_s }, body]
    end
    @server = Thin::Server.new('0.0.0.0', 3333, app)
    @server.timeout = 3
    @server.silent = true
    
    @thread = Thread.new { @server.start }
    sleep 0.1 until @thread.status == 'sleep'
  end
    
  it 'should GET from Net::HTTP' do
    get('/?cthis').should include('cthis')
  end
  
  it 'should GET from TCPSocket' do
    raw("GET /?this HTTP/1.1\r\n\r\n").
      should include("HTTP/1.1 200 OK",
                     "Content-Type: text/html", "Content-Length: ",
                     "Connection: close", "this")
  end
  
  it 'should return empty string on incomplete headers' do
    raw("GET /?this HTTP/1.1\r\nHost:").should be_empty
  end
  
  it 'should return empty string on incorrect Content-Length' do
    raw("POST / HTTP/1.1\r\nContent-Length: 300\r\n\r\naye").should be_empty
  end
  
  it 'should POST from Net::HTTP' do
    post('/', :arg => 'pirate').should include('arg=pirate')
  end
  
  it 'should handle big POST' do
    big = 'X' * (20 * 1024)
    post('/', :big => big).should include(big)
  end
  
  it "should handle GET in less then #{get_request_time = 0.004} RubySecond" do
    proc { get('/') }.should be_faster_then(get_request_time)
  end
  
  it "should handle POST in less then #{post_request_time = 0.007} RubySecond" do
    proc { post('/', :file => 'X' * 1000) }.should be_faster_then(post_request_time)
  end
  
  it "should retreive remote address" do
    get('/').should include('"REMOTE_ADDR"=>"127.0.0.1"')
  end
  
  it "should wait for current requests before soft stopping" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write("GET / HTTP/1.1")
    @server.stop # Stop the server in the middle of a request
    socket.write("\r\n\r\n")
    
    out = socket.read
    socket.close
    
    out.should_not be_empty
  end
  
  it "should not accept new requests when soft stopping" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write("GET / HTTP/1.1")
    @server.stop # Stop the server in the middle of a request
    
    EventMachine.next_tick do
      proc { get('/') }.should raise_error(Errno::ECONNRESET)
    end
    
    socket.close
  end
  
  it "should drop current requests when hard stopping" do
    socket = TCPSocket.new('0.0.0.0', 3333)
    socket.write("GET / HTTP/1.1")
    @server.stop! # Force stop the server in the middle of a request
    
    EventMachine.next_tick { socket.should be_closed }
  end
  
  after do
    @server.stop!
    @thread.kill
  end
  
  private
    def get(url)
      Net::HTTP.get(URI.parse('http://0.0.0.0:3333' + url))
    end
    
    def raw(data)
      socket = TCPSocket.new('0.0.0.0', 3333)
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

describe Server, "on UNIX domain socket" do
  before do
    app = proc do |env|
      [200, { 'Content-Type' => 'text/html' }, [env.inspect]]
    end
    @server = Thin::Server.new('/tmp/thin_test.sock', nil, app)
    @server.timeout = 3
    @server.silent = true
    
    @thread = Thread.new { @server.start }
    sleep 0.1 until @thread.status == 'sleep'
  end
  
  it "should accept GET request" do
    get("/?this").should include('this')
  end
  
  it "should retreive remote address" do    
    get('/').should include('"REMOTE_ADDR"=>""') # Is that right?
  end
  
  it "should handle GET in less then #{get_request_time = 0.002} RubySecond" do
    proc { get('/') }.should be_faster_then(get_request_time)
  end
  
  it "should remove socket file after server stops" do
    @server.stop!
    File.exist?('/tmp/thin_test.sock').should be_false
  end
  
  after do
    @server.stop!
    @thread.kill
  end
  
  private
    def get(url)
      send_data("GET #{url} HTTP/1.1\r\n\r\n")
    end
  
    def send_data(data)
      socket = UNIXSocket.new('/tmp/thin_test.sock')
      socket.write data
      out = socket.read
      socket.close
      out
    end
end