require File.dirname(__FILE__) + '/spec_helper'

describe Connection do
  before do
    @connection = Connection.new(mock('EM', :null_object => true))
    @connection.silent = true
    @connection.post_init
    @connection.app = proc do |env|
      [200, {}, ['']]
    end
  end
  
  it "should parse on receive_data" do
    @connection.request.should_receive(:parse).with('GET')
    @connection.receive_data('GET')
  end

  it "should close connection on InvalidRequest error in receive_data" do
    @connection.request.stub!(:parse).and_raise(InvalidRequest)
    @connection.should_receive(:close_connection)
    @connection.receive_data('')
  end
  
  it "should process when parsing complete" do
    @connection.request.should_receive(:parse).and_return(true)
    @connection.should_receive(:process)
    @connection.receive_data('GET')
  end
  
  it "should process" do
    @connection.process
  end
  
  it "should return HTTP_X_FORWARDED_FOR as remote_address" do
    @connection.request.env['HTTP_X_FORWARDED_FOR'] = '1.2.3.4'
    @connection.remote_address.should == '1.2.3.4'
  end
  
  it "should return nil on error retreiving remote_address" do
    @connection.stub!(:get_peername).and_raise(RuntimeError)
    @connection.remote_address.should be_nil
  end
  
  it "should return remote_address" do
    @connection.stub!(:get_peername).and_return("\020\002?E\177\000\000\001\000\000\000\000\000\000\000\000")
    @connection.remote_address.should == '127.0.0.1'
  end
end