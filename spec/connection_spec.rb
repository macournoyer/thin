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
    expect(@connection.request).to receive(:parse).with('GET')
    @connection.receive_data('GET')
  end

  it "should make a valid response on bad request" do
    allow(@connection.request).to receive(:parse).and_raise(InvalidRequest)
    expect(@connection).to receive(:post_process).with(Response::BAD_REQUEST)
    @connection.receive_data('')
  end

  it "should close connection on InvalidRequest error in receive_data" do
    allow(@connection.request).to receive(:parse).and_raise(InvalidRequest)
    allow(@connection.response).to receive(:persistent?) { false }
    @connection.can_persist!
    expect(@connection).to receive(:terminate_request)
    @connection.receive_data('')
  end

  it "should process when parsing complete" do
    expect(@connection.request).to receive(:parse).and_return(true)
    expect(@connection).to receive(:process)
    @connection.receive_data('GET')
  end

  it "should process at most once when request is larger than expected" do
    expect(@connection).to receive(:process).at_most(1)
    @connection.receive_data("POST / HTTP/1.1\r\nHost: localhost:3000\r\nContent-Length: 300\r\n\r\n")
    10.times { @connection.receive_data('X' * 1_000) }
  end

  it "should process" do
    @connection.process
  end

  it "should rescue error in process" do
    expect(@connection.app).to receive(:call).and_raise(StandardError)
    allow(@connection.response).to receive(:persistent?) { false }
    expect(@connection).to receive(:terminate_request)
    @connection.process
  end

  it "should make response on error" do
    expect(@connection.app).to receive(:call).and_raise(StandardError)
    expect(@connection).to receive(:post_process).with(Response::ERROR)
    @connection.process
  end

  it "should not close persistent connection on error" do
    expect(@connection.app).to receive(:call).and_raise(StandardError)
    allow(@connection.response).to receive(:persistent?) { true }
    @connection.can_persist!
    expect(@connection).to receive(:teminate_request).never
    @connection.process
  end

  it "should rescue Timeout error in process" do
    expect(@connection.app).to receive(:call).and_raise(Timeout::Error.new("timeout error not rescued"))
    @connection.process
  end
  
  it "should not return HTTP_X_FORWARDED_FOR as remote_address" do
    @connection.request.env['HTTP_X_FORWARDED_FOR'] = '1.2.3.4'
    allow(@connection).to receive(:socket_address) { "127.0.0.1" }
    expect(@connection.remote_address).to eq("127.0.0.1")
  end
  
  it "should return nil on error retrieving remote_address" do
    allow(@connection).to receive(:get_peername).and_raise(RuntimeError)
    expect(@connection.remote_address).to be_nil
  end
  
  it "should return nil on nil get_peername" do
    allow(@connection).to receive(:get_peername) { nil }
    expect(@connection.remote_address).to be_nil
  end
  
  it "should return nil on empty get_peername" do
    allow(@connection).to receive(:get_peername) { '' }
    expect(@connection.remote_address).to be_nil
  end
  
  it "should return remote_address" do
    allow(@connection).to receive(:get_peername) do
      Socket.pack_sockaddr_in(3000, '127.0.0.1')
    end
    expect(@connection.remote_address).to eq('127.0.0.1')
  end
  
  it "should not be persistent" do
    expect(@connection).not_to be_persistent
  end

  it "should be persistent when response is and allowed" do
    allow(@connection.response).to receive(:persistent?) { true }
    @connection.can_persist!
    expect(@connection).to be_persistent
  end

  it "should not be persistent when response is but not allowed" do
    @connection.response.persistent!
    expect(@connection).not_to be_persistent
  end
  
  it "should return empty body on HEAD request" do
    expect(@connection.request).to receive(:head?).and_return(true)
    expect(@connection).to receive(:send_data).once # Only once for the headers
    @connection.process
  end
  
  it "should set request env as rack.multithread" do
    expect(EventMachine).to receive(:defer)
    
    @connection.threaded = true
    @connection.process
    
    expect(@connection.request.env["rack.multithread"]).to eq(true)
  end
  
  it "should set as threaded when app.deferred? is true" do
    expect(@connection.app).to receive(:deferred?).and_return(true)
    expect(@connection).to be_threaded
  end
  
  it "should not set as threaded when app.deferred? is false" do
    expect(@connection.app).to receive(:deferred?).and_return(false)
    expect(@connection).not_to be_threaded
  end

  it "should not set as threaded when app do not respond to deferred?" do
    expect(@connection).not_to be_threaded
  end

  it "should have correct SERVER_PORT when using ssl" do
    @connection.backend = double("backend", :ssl? => true, :port => 443)

    @connection.process

    expect(@connection.request.env["SERVER_PORT"]).to eq("443")
  end
end
