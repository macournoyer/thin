require 'spec_helper'

describe Backends::TcpServer do
  before do
    @backend = Backends::TcpServer.new('0.0.0.0', 3333)
  end
  
  it "should not use epoll if disabled" do
    @backend.no_epoll = true
    EventMachine.should_not_receive(:epoll)
    @backend.config
  end
  
  it "should use epoll if supported" do
    if EventMachine.epoll?
      EventMachine.should_receive(:epoll)
    else
      EventMachine.should_not_receive(:epoll)
    end
    @backend.config
  end

  it "should not use kqueue if disabled" do
    @backend.no_kqueue = true
    EventMachine.should_not_receive(:kqueue)
    @backend.config
  end

  it "should use kqueue if supported" do
    if EventMachine.kqueue?
      EventMachine.should_receive(:kqueue)
    else
      EventMachine.should_not_receive(:kqueue)
    end
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
