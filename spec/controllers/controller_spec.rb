require 'spec_helper'
require 'ostruct'
include Controllers

describe Controller, 'start' do
  before do
    @controller = Controller.new(:address              => '0.0.0.0',
                                 :port                 => 3000,
                                 :pid                  => 'thin.pid',
                                 :log                  => 'thin.log',
                                 :timeout              => 60,
                                 :max_conns            => 2000,
                                 :max_persistent_conns => 1000,
                                 :adapter              => 'rails')
    
    @server = OpenStruct.new
    @adapter = OpenStruct.new
    
    expect(Server).to receive(:new).with('0.0.0.0', 3000, @controller.options).and_return(@server)
    expect(@server).to receive(:config)
    allow(Rack::Adapter::Rails).to receive(:new) { @adapter }
  end
  
  it "should configure server" do
    @controller.start
    
    expect(@server.app).to eq(@adapter)
    expect(@server.pid_file).to eq('thin.pid')
    expect(@server.log_file).to eq('thin.log')
    expect(@server.maximum_connections).to eq(2000)
    expect(@server.maximum_persistent_connections).to eq(1000)
  end
  
  it "should start as daemon" do
    @controller.options[:daemonize] = true
    @controller.options[:user] = true
    @controller.options[:group] = true
    
    expect(@server).to receive(:daemonize)
    expect(@server).to receive(:change_privilege)

    @controller.start
  end
  
  it "should configure Rails adapter" do
    expect(Rack::Adapter::Rails).to receive(:new).with(@controller.options.merge(:root => nil))
    
    @controller.start
  end
  
  it "should mount app under :prefix" do
    @controller.options[:prefix] = '/app'
    @controller.start
    
    expect(@server.app.class).to eq(Rack::URLMap)
  end

  it "should mount Stats adapter under :stats" do
    @controller.options[:stats] = '/stats'
    @controller.start
    
    expect(@server.app.class).to eq(Stats::Adapter)
  end
  
  it "should load app from Rack config" do
    @controller.options[:rackup] = File.dirname(__FILE__) + '/../../example/config.ru'
    @controller.start
    
    expect(@server.app.class).to eq(Proc)
  end

  it "should load app from ruby file" do
    @controller.options[:rackup] = File.dirname(__FILE__) + '/../../example/myapp.rb'
    @controller.start
    
    expect(@server.app).to eq(Myapp)
  end

  it "should throwup if rackup is not a .ru or .rb file" do
    expect do
      @controller.options[:rackup] = File.dirname(__FILE__) + '/../../example/myapp.foo'
      @controller.start
    end.to raise_error(RuntimeError, /please/)
  end
  
  it "should set server as threaded" do
    @controller.options[:threaded] = true
    @controller.start
    
    expect(@server.threaded).to be_truthy
  end
  
  it "should set RACK_ENV" do
    @controller.options[:rackup] = File.dirname(__FILE__) + '/../../example/config.ru'
    @controller.options[:environment] = "lolcat"
    @controller.start
    
    expect(ENV['RACK_ENV']).to eq("lolcat")
  end
    
end

describe Controller do
  before do
    @controller = Controller.new(:pid => 'thin.pid', :timeout => 10)
    allow(@controller).to receive(:wait_for_file)
  end
  
  it "should stop" do
    expect(Server).to receive(:kill).with('thin.pid', 10)
    @controller.stop
  end
  
  it "should restart" do
    expect(Server).to receive(:restart).with('thin.pid')
    @controller.restart
  end
  
  it "should write configuration file" do
    silence_stream(STDOUT) do
      Controller.new(:config => 'test.yml', :port => 5000, :address => '127.0.0.1').config
    end

    expect(File.read('test.yml')).to include('port: 5000', 'address: 127.0.0.1')
    expect(File.read('test.yml')).not_to include('config: ')

    File.delete('test.yml')
  end
end
