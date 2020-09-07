require 'spec_helper'
include Controllers

describe Cluster, "with host and port" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid'
                          )
  end
    
  it 'should include port number in file names' do
    expect(@cluster.send(:include_server_number, 'thin.log', 3000)).to eq('thin.3000.log')
    expect(@cluster.send(:include_server_number, 'thin.pid', 3000)).to eq('thin.3000.pid')
  end
  
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |port|
      calls << port
    end
    expect(calls).to eq([3000, 3001, 3002])
  end
    
  it 'should start on each port' do
    expect(Command).to receive(:run).with(:start, options_for_port(3000))
    expect(Command).to receive(:run).with(:start, options_for_port(3001))
    expect(Command).to receive(:run).with(:start, options_for_port(3002))

    @cluster.start
  end

  it 'should stop on each port' do
    expect(Command).to receive(:run).with(:stop, options_for_port(3000))
    expect(Command).to receive(:run).with(:stop, options_for_port(3001))
    expect(Command).to receive(:run).with(:stop, options_for_port(3002))

    @cluster.stop
  end
  
  private
    def options_for_port(port)
      { :daemonize => true, :log => "thin.#{port}.log", :timeout => 10, :address => "0.0.0.0", :port => port, :pid => "thin.#{port}.pid", :chdir => "/rails_app" }
    end
end

describe Cluster, "with UNIX socket" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :socket => '/tmp/thin.sock',
                           :address => '0.0.0.0',
                           :port => 3000,
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid'
                          )
  end
  
  it 'should include socket number in file names' do
    expect(@cluster.send(:include_server_number, 'thin.sock', 0)).to eq('thin.0.sock')
    expect(@cluster.send(:include_server_number, 'thin', 0)).to eq('thin.0')
  end
  
  it "should exclude :address and :port options" do
    expect(@cluster.options).not_to have_key(:address)
    expect(@cluster.options).not_to have_key(:port)
  end
  
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    expect(calls).to eq([0, 1, 2])
  end
  
  it 'should start each server' do
    expect(Command).to receive(:run).with(:start, options_for_socket(0))
    expect(Command).to receive(:run).with(:start, options_for_socket(1))
    expect(Command).to receive(:run).with(:start, options_for_socket(2))

    @cluster.start
  end

  it 'should stop each server' do
    expect(Command).to receive(:run).with(:stop, options_for_socket(0))
    expect(Command).to receive(:run).with(:stop, options_for_socket(1))
    expect(Command).to receive(:run).with(:stop, options_for_socket(2))

    @cluster.stop
  end
  
  
  private
    def options_for_socket(number)
      { :daemonize => true, :log => "thin.#{number}.log", :timeout => 10, :socket => "/tmp/thin.#{number}.sock", :pid => "thin.#{number}.pid", :chdir => "/rails_app" }
    end
end

describe Cluster, "controlling only one server" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :only => 3001
                          )
  end
  
  it 'should call only specified server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    expect(calls).to eq([3001])
  end
  
  it "should start only specified server" do
    expect(Command).to receive(:run).with(:start, options_for_port(3001))

    @cluster.start
  end
  
  private
    def options_for_port(port)
      { :daemonize => true, :log => "thin.#{port}.log", :timeout => 10, :address => "0.0.0.0", :port => port, :pid => "thin.#{port}.pid", :chdir => "/rails_app" }
    end
end

describe Cluster, "controlling only one server with UNIX socket" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :socket => '/tmp/thin.sock',
                           :address => '0.0.0.0',
                           :port => 3000,
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :only => 1
                          )
  end
  
  it 'should call only specified server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    expect(calls).to eq([1])
  end
end

describe Cluster, "controlling only one server, by sequence number" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :only => 1
                          )
  end
  
  it 'should call only specified server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    expect(calls).to eq([3001])
  end
  
  it "should start only specified server" do
    expect(Command).to receive(:run).with(:start, options_for_port(3001))

    @cluster.start
  end
  
  private
    def options_for_port(port)
      { :daemonize => true, :log => "thin.#{port}.log", :timeout => 10, :address => "0.0.0.0", :port => port, :pid => "thin.#{port}.pid", :chdir => "/rails_app" }
    end
end

describe Cluster, "with Swiftiply" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :swiftiply => true
                          )
  end
  
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    expect(calls).to eq([0, 1, 2])
  end
  
  it 'should start each server' do
    expect(Command).to receive(:run).with(:start, options_for_swiftiply(0))
    expect(Command).to receive(:run).with(:start, options_for_swiftiply(1))
    expect(Command).to receive(:run).with(:start, options_for_swiftiply(2))

    @cluster.start
  end

  it 'should stop each server' do
    expect(Command).to receive(:run).with(:stop, options_for_swiftiply(0))
    expect(Command).to receive(:run).with(:stop, options_for_swiftiply(1))
    expect(Command).to receive(:run).with(:stop, options_for_swiftiply(2))

    @cluster.stop
  end
  
  private
    def options_for_swiftiply(number)
      { :address => '0.0.0.0', :port => 3000, :daemonize => true, :log => "thin.#{number}.log", :timeout => 10, :pid => "thin.#{number}.pid", :chdir => "/rails_app", :swiftiply => true }
    end
end

describe Cluster, "rolling restart" do
  before do
    @cluster = Cluster.new(:chdir => '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 2,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :onebyone => true,
                           :wait => 30
                          )
  end
  
  it "should restart servers one by one" do
    expect(Command).to receive(:run).with(:stop, options_for_port(3000))
    expect(Command).to receive(:run).with(:start, options_for_port(3000))
    expect(@cluster).to receive(:wait_until_server_started).with(3000)
    
    expect(Command).to receive(:run).with(:stop, options_for_port(3001))
    expect(Command).to receive(:run).with(:start, options_for_port(3001))
    expect(@cluster).to receive(:wait_until_server_started).with(3001)
    
    @cluster.restart
  end
  
  private
    def options_for_port(port)
      { :daemonize => true, :log => "thin.#{port}.log", :timeout => 10, :address => "0.0.0.0", :port => port, :pid => "thin.#{port}.pid", :chdir => "/rails_app" }
    end
end