require 'spec_helper'

describe Backends::TcpServer do
  before do
    @backend = Backends::TcpServer.new('0.0.0.0', 3333)
  end
  
  it "should not use epoll" do
    @backend.no_epoll = true
    expect(EventMachine).not_to receive(:epoll)
    @backend.config
  end
  
  it "should use epoll" do
    expect(EventMachine).to receive(:epoll)
    @backend.config
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
end
