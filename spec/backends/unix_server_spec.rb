require 'spec_helper'

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
    expect(File.exist?('/tmp/thin-test.sock')).to be_falsey
  end
end

describe UnixConnection do
  before do
    @connection = UnixConnection.new(nil)
  end
  
  it "should return 127.0.0.1 as remote_address" do
    expect(@connection.remote_address).to eq('127.0.0.1')
  end
end
