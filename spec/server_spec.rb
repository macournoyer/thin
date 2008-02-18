require File.dirname(__FILE__) + '/spec_helper'

describe Server do
  before do
    @server = Server.new('0.0.0.0', 3000)
  end
  
  it "should set descriptor table size" do
    @server.should_receive(:log).once
    @server.descriptor_table_size = 100
    @server.descriptor_table_size.should == 100
  end

  it "should warn when descriptor table size too large" do
    @server.stub!(:log)
    @server.should_receive(:log).with(/^!! descriptor table size smaller then requested/)
    @server.descriptor_table_size = 100_000
    @server.descriptor_table_size.should < 100_000
  end
end