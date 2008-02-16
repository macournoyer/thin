require File.dirname(__FILE__) + '/../spec_helper'

describe Server, 'on TCP socket' do
  before do
    start_server do |env|
      body = env.inspect + env['rack.input'].read
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => body.size.to_s }, body]
    end
  end
    
  it 'should GET from Net::HTTP' do
    get('/?cthis').should include('cthis')
  end
  
  it 'should GET from TCPSocket' do
    send_data("GET /?this HTTP/1.1\r\nConnection: close\r\n\r\n").
      should include("HTTP/1.1 200 OK",
                     "Content-Type: text/html", "Content-Length: ",
                     "Connection: close", "this")
  end
  
  it 'should return empty string on incomplete headers' do
    send_data("GET /?this HTTP/1.1\r\nHost:").should be_empty
  end
  
  it 'should return empty string on incorrect Content-Length' do
    send_data("POST / HTTP/1.1\r\nContent-Length: 300\r\nConnection: close\r\n\r\naye").should be_empty
  end
  
  it 'should POST from Net::HTTP' do
    post('/', :arg => 'pirate').should include('arg=pirate')
  end
  
  it 'should handle big POST' do
    big = 'X' * (20 * 1024)
    post('/', :big => big).should include(big)
  end
  
  it "should handle GET in less then #{get_request_time = 0.0045} RubySecond" do
    proc { get('/') }.should be_faster_then(get_request_time)
  end
  
  it "should handle POST in less then #{post_request_time = 0.007} RubySecond" do
    proc { post('/', :file => 'X' * 1000) }.should be_faster_then(post_request_time)
  end
  
  it "should retreive remote address" do
    get('/').should include('"REMOTE_ADDR"=>"127.0.0.1"')
  end
  
  after do
    stop_server
  end
end
