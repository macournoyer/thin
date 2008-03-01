require File.dirname(__FILE__) + '/../spec_helper'

describe Backends::UnixServer do
  before do
    @backend = Backends::UnixServer.new('/tmp/thin-test.sock')
  end
  
  it "should connect" do
    EventMachine.run do
      @backend.connect
      EventMachine.stop
    end
  end
  
  it "should disconnect" do
    EventMachine.run do
      @backend.connect
      @backend.disconnect
      EventMachine.stop
    end
  end
  
  it "should remove socket file on close" do
    @backend.close
    File.exist?('/tmp/thin-test.sock').should be_false
  end
end

describe UnixConnection do
  before do
    @connection = UnixConnection.new(nil)
  end
  
  it "should return 0.0.0.0 as remote_address" do
    @connection.remote_address.should == '0.0.0.0'
  end
end