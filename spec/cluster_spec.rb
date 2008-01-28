require File.dirname(__FILE__) + '/spec_helper'

describe Cluster, "with host and port" do
  before do
    @cluster = Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid'
                          )
    @cluster.script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster.silent = true
  end
    
  it 'should include port number in file names' do
    @cluster.send(:include_server_number, 'thin.log', 3000).should == 'thin.3000.log'
    @cluster.send(:include_server_number, 'thin.pid', 3000).should == 'thin.3000.pid'
  end
    
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |port|
      calls << port
    end
    calls.should == [3000, 3001, 3002]
  end
  
  it 'should shellify command' do
    out = @cluster.send(:shellify, :start, :port => 3000, :daemonize => true, :log => 'hi.log', :pid => nil)
    out.should include('--port=3000', '--daemonize', '--log="hi.log"', 'thin start --')
    out.should_not include('--pid=')
  end
  
  it 'should start on specified port' do
    @cluster.should_receive(:`) do |with|
      with.should include('thin start', '--daemonize', 'thin.3001.log', 'thin.3001.pid', '--port=3001')
      with.should_not include('--socket')
      ''
    end

    @cluster.start_server 3001    
  end

  it 'should stop on specified port' do
    @cluster.should_receive(:`) do |with|
      with.should include('thin stop', '--daemonize', 'thin.3001.log', 'thin.3001.pid', '--port=3001')
      with.should_not include('--socket')
      ''
    end

    @cluster.stop_server 3001
  end
end

describe Cluster, "with UNIX socket" do
  before do
    @cluster = Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                           :socket => '/tmp/thin.sock',
                           :address => '0.0.0.0',
                           :port => 3000,
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid'
                          )
    @cluster.script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster.silent = true
  end
  
  it 'should include socket number in file names' do
    @cluster.send(:include_server_number, 'thin.sock', 0).should == 'thin.0.sock'
    @cluster.send(:include_server_number, 'thin', 0).should == 'thin.0'
  end
  
  it 'should call each server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    calls.should == [0, 1, 2]
  end
  
  it 'should start specified server' do
    @cluster.should_receive(:`) do |with|
      with.should include('thin start', '--daemonize', 'thin.1.log', 'thin.1.pid', '--socket="/tmp/thin.1.sock"')
      with.should_not include('--port', '--address')
      ''
    end

    @cluster.start_server 1
  end

  it 'should stop specified server' do
    @cluster.should_receive(:`) do |with|
      with.should include('thin stop', '--daemonize', 'thin.1.log', 'thin.1.pid', '--socket="/tmp/thin.1.sock"')
      with.should_not include('--port', '--address')
      ''
    end

    @cluster.stop_server 1
  end
end

describe Cluster, "controlling only one server" do
  before do
    @cluster = Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                           :address => '0.0.0.0',
                           :port => 3000, 
                           :servers => 3,
                           :timeout => 10,
                           :log => 'thin.log',
                           :pid => 'thin.pid',
                           :only => 3001
                          )
    @cluster.script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster.silent = true
  end
  
  it 'should call only specified server' do
    calls = []
    @cluster.send(:with_each_server) do |n|
      calls << n
    end
    calls.should == [3001]
  end
  
  it "should start only specified server" do
    @cluster.should_receive(:`) do |with|
      with.should include('thin start', '--daemonize', 'thin.3001.log', 'thin.3001.pid', '--port=3001')
      with.should_not include('3000', '3002')
      ''
    end

    @cluster.start
  end
end