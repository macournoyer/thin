require 'spec_helper'

describe Server do
  before do
    @server = Server.new('0.0.0.0', 3000)
  end
  
  it "should set maximum_connections size" do
    @server.maximum_connections = 100
    @server.config
    expect(@server.maximum_connections).to eq(100)
  end

  it "should set lower maximum_connections size when too large" do
    # root users under Linux will not have a limitation on maximum
    # connections, so we cannot really run this test under that
    # condition.
    pending("only for non-root users") if Process.euid == 0
    maximum_connections = 1_000_000
    @server.maximum_connections = maximum_connections
    @server.config
    expect(@server.maximum_connections).to be <= maximum_connections
  end
  
  it "should default to non-threaded" do
    expect(@server).not_to be_threaded
  end
  
  it "should set backend to threaded" do
    @server.threaded = true
    expect(@server.backend).to be_threaded
  end

  it "should set the threadpool" do
    @server.threadpool_size = 10
    expect(@server.threadpool_size).to eq(10)
  end
end

describe Server, "initialization" do
  it "should set host and port" do
    server = Server.new('192.168.1.1', 8080)

    expect(server.host).to eq('192.168.1.1')
    expect(server.port).to eq(8080)
  end

  it "should set socket" do
    server = Server.new('/tmp/thin.sock')

    expect(server.socket).to eq('/tmp/thin.sock')
  end
  
  it "should set host, port and app" do
    app = proc {}
    server = Server.new('192.168.1.1', 8080, app)
    
    expect(server.host).not_to be_nil
    expect(server.app).to eq(app)
  end

  it "should set socket and app" do
    app = proc {}
    server = Server.new('/tmp/thin.sock', app)
    
    expect(server.socket).not_to be_nil
    expect(server.app).to eq(app)
  end

  it "should set socket, nil and app" do
    app = proc {}
    server = Server.new('/tmp/thin.sock', nil, app)
    
    expect(server.socket).not_to be_nil
    expect(server.app).to eq(app)
  end
  
  it "should set host, port and backend" do
    server = Server.new('192.168.1.1', 8080, :backend => Thin::Backends::SwiftiplyClient)
    
    expect(server.host).not_to be_nil
    expect(server.backend).to be_kind_of(Thin::Backends::SwiftiplyClient)
  end  

  it "should set host, port, app and backend" do
    app = proc {}
    server = Server.new('192.168.1.1', 8080, app, :backend => Thin::Backends::SwiftiplyClient)
    
    expect(server.host).not_to be_nil
    expect(server.app).to eq(app)
    expect(server.backend).to be_kind_of(Thin::Backends::SwiftiplyClient)
  end
  
  it "should set port as string" do
    app = proc {}
    server = Server.new('192.168.1.1', '8080')
    
    expect(server.host).to eq('192.168.1.1')
    expect(server.port).to eq(8080)
  end
  
  it "should not register signals w/ :signals => false" do
    expect(Server).not_to receive(:setup_signals)
    Server.new(:signals => false)
  end
end