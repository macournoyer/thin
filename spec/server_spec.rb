require File.dirname(__FILE__) + '/spec_helper'

describe Server do
  before do
    @server = Server.new('0.0.0.0', 3000)
  end
  
  it "should set maximum_connections size" do
    @server.maximum_connections = 100
    @server.config
    @server.maximum_connections.should == 100
  end

  it "should set lower maximum_connections size when too large" do
    @server.maximum_connections = 100_000
    @server.config
    @server.maximum_connections.should < 100_000
  end
end