require 'spec_helper'

describe Backends::SwiftiplyClient do
  before do
    @backend = Backends::SwiftiplyClient.new('0.0.0.0', 3333)
    @backend.server = double('server').as_null_object
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

describe SwiftiplyConnection do
  before do
    @connection = SwiftiplyConnection.new(nil)
    @connection.backend = Backends::SwiftiplyClient.new('0.0.0.0', 3333)
    @connection.backend.server = double('server').as_null_object
  end
  
  it do
    expect(@connection).to be_persistent
  end
  
  it "should send handshake on connection_completed" do
    expect(@connection).to receive(:send_data).with('swiftclient000000000d0500')
    @connection.connection_completed
  end
  
  it "should reconnect on unbind" do
    allow(@connection.backend).to receive(:running?) { true }
    allow(@connection).to receive(:rand) { 0 } # Make sure we don't wait
    
    expect(@connection).to receive(:reconnect).with('0.0.0.0', 3333)
    
    EventMachine.run do
      @connection.unbind
      EventMachine.add_timer(0) { EventMachine.stop }      
    end
  end
  
  it "should not reconnect when not running" do
    allow(@connection.backend).to receive(:running?) { false }
    expect(EventMachine).not_to receive(:add_timer)
    @connection.unbind
  end
  
  it "should have a host_ip" do
    expect(@connection.send(:host_ip)).to eq([0, 0, 0, 0])
  end
  
  it "should generate swiftiply_handshake based on key" do
    expect(@connection.send(:swiftiply_handshake, 'key')).to eq('swiftclient000000000d0503key')
  end
end
