require File.dirname(__FILE__) + '/../spec_helper'

describe Connectors::UnixServer do
end

describe UnixConnection do
  before do
    @connection = UnixConnection.new(nil)
  end
  
  it "should return nil on error retreiving remote_address" do
    @connection.stub!(:get_peername).and_raise(RuntimeError)
    @connection.remote_address.should be_nil
  end
  
  it "should return remote_address" do
    @connection.stub!(:get_peername).and_return("\000\001127.0.0.1\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000")
    @connection.remote_address.should == '127.0.0.1'
  end
end