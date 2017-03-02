require 'spec_helper'

describe Connection do
  before do
    allow(EventMachine).to receive(:send_data)
    @connection = Connection.new(double('EM').as_null_object)
    @connection.post_init
    @connection.backend = double("backend", :ssl? => false)
    @connection.app = proc do |env|
      [200, {}, ['body']]
    end
  end
  
  it "should parse on receive_data" do
    @connection.request.should_receive(:parse).with('GET')
    @connection.receive_data('GET')
  end

  it "should make a valid response on bad request" do
    allow(@connection.request).to receive(:parse).and_raise(InvalidRequest)
    @connection.should_receive(:post_process).with(Response::BAD_REQUEST)
    @connection.receive_data('')
  end

  it "should close connection on InvalidRequest error in receive_data" do
    allow(@connection.request).to receive(:parse).and_raise(InvalidRequest)
    allow(@connection.response).to receive(:persistent?) { false }
    @connection.can_persist!
    @connection.should_receive(:terminate_request)
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

  it "should rescue error in process" do
    @connection.app.should_receive(:call).and_raise(StandardError)
    allow(@connection.response).to receive(:persistent?) { false }
    @connection.should_receive(:terminate_request)
    @connection.process
  end

  it "should make response on error" do
    @connection.app.should_receive(:call).and_raise(StandardError)
    @connection.should_receive(:post_process).with(Response::ERROR)
    @connection.process
  end

  it "should not close persistent connection on error" do
    @connection.app.should_receive(:call).and_raise(StandardError)
    allow(@connection.response).to receive(:persistent?) { true }
    @connection.can_persist!
    @connection.should_receive(:teminate_request).never
    @connection.process
  end

  it "should rescue Timeout error in process" do
    @connection.app.should_receive(:call).and_raise(Timeout::Error.new("timeout error not rescued"))
    @connection.process
  end
  
  it "should not return HTTP_X_FORWARDED_FOR as remote_address" do
    @connection.request.env['HTTP_X_FORWARDED_FOR'] = '1.2.3.4'
    allow(@connection).to receive(:socket_address) { "127.0.0.1" }
    @connection.remote_address.should == "127.0.0.1"
  end
  
  it "should return nil on error retreiving remote_address" do
    allow(@connection).to receive(:get_peername).and_raise(RuntimeError)
    @connection.remote_address.should be_nil
  end
  
  it "should return nil on nil get_peername" do
    allow(@connection).to receive(:get_peername) { nil }
    @connection.remote_address.should be_nil
  end
  
  it "should return nil on empty get_peername" do
    allow(@connection).to receive(:get_peername) { '' }
    @connection.remote_address.should be_nil
  end
  
  it "should return remote_address" do
    allow(@connection).to receive(:get_peername) do
      Socket.pack_sockaddr_in(3000, '127.0.0.1')
    end
    @connection.remote_address.should == '127.0.0.1'
  end
  
  it "should not be persistent" do
    @connection.should_not be_persistent
  end

  it "should be persistent when response is and allowed" do
    allow(@connection.response).to receive(:persistent?) { true }
    @connection.can_persist!
    @connection.should be_persistent
  end

  it "should not be persistent when response is but not allowed" do
    @connection.response.persistent!
    @connection.should_not be_persistent
  end
  
  it "should return empty body on HEAD request" do
    @connection.request.should_receive(:head?).and_return(true)
    @connection.should_receive(:send_data).once # Only once for the headers
    @connection.process
  end
  
  it "should set request env as rack.multithread" do
    EventMachine.should_receive(:defer)
    
    @connection.threaded = true
    @connection.process
    
    @connection.request.env["rack.multithread"].should == true
  end
  
  it "should set as threaded when app.deferred? is true" do
    @connection.app.should_receive(:deferred?).and_return(true)
    @connection.should be_threaded
  end
  
  it "should not set as threaded when app.deferred? is false" do
    @connection.app.should_receive(:deferred?).and_return(false)
    @connection.should_not be_threaded
  end

  it "should not set as threaded when app do not respond to deferred?" do
    @connection.should_not be_threaded
  end
end
