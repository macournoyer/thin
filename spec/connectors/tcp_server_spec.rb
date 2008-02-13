require File.dirname(__FILE__) + '/../spec_helper'

describe Connectors::TcpServer do
  before do
    @connector = Connectors::TcpServer.new('0.0.0.0', 3333)
  end
  
  it "should connect" do
    EventMachine.run do
      @connector.connect
      EventMachine.stop
    end
  end
  
  it "should disconnect" do
    EventMachine.run do
      @connector.connect
      @connector.disconnect
      EventMachine.stop
    end
  end
end
