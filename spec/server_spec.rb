require File.dirname(__FILE__) + '/spec_helper'

describe Server do
  before do
    @server = Server.new('0.0.0.0', 3000)
  end
  
  it "should set descriptor table size" do
    @server.should_receive(:log).once
    @server.maximum_connections = 100
    @server.set_descriptor_table_size!
    @server.maximum_connections.should == 100
  end

  it "should warn when descriptor table size too large" do
    @server.stub!(:log)
    @server.should_receive(:log).with(/^!!/)
    @server.maximum_connections = 100_000
    @server.set_descriptor_table_size!
    @server.maximum_connections.should < 100_000
  end
end