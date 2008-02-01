require File.dirname(__FILE__) + '/../spec_helper'

describe Server, "on UNIX domain socket" do
  before do
    start_server('/tmp/thin_test.sock') do |env|
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => env.inspect.size.to_s }, [env.inspect]]
    end
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
    stop_server
  end
end