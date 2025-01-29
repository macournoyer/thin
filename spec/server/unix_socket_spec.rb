require 'spec_helper'

describe Server, "on UNIX domain socket" do
  before do
    start_server('/tmp/thin_test.sock') do |env|
      [200, { 'content-type' => 'text/html' }, [env.inspect]]
    end
  end
  
  it "should accept GET request" do
    expect(get("/?this")).to include('this')
  end
  
  it "should retreive remote address" do
    expect(get('/')).to be =~ /"REMOTE_ADDR"\s*=>\s*"127.0.0.1"/
  end
  
  it "should remove socket file after server stops" do
    @server.stop!
    expect(File.exist?('/tmp/thin_test.sock')).to be_falsey
  end
  
  after do
    stop_server
  end
end
