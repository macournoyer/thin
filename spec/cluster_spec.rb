require File.dirname(__FILE__) + '/spec_helper'

describe Cluster do
  before do
    Thin::Cluster.thin_script = File.dirname(__FILE__) + '/../bin/thin'
    @cluster = Thin::Cluster.new(:chdir => File.dirname(__FILE__) + '/rails_app',
                                 :address => '0.0.0.0',
                                 :port => 3000, 
                                 :servers => 3,
                                 :timeout => 10,
                                 :log => 'thin.log',
                                 :pid => 'thin.pid'
                                )
    @cluster.silent = true
  end
    
  it 'should include port number in file names' do
    @cluster.send(:include_port_number, 'thin.log', 3000).should == 'thin.3000.log'
    @cluster.send(:include_port_number, 'thin.pid', 3000).should == 'thin.3000.pid'
    proc { @cluster.send(:include_port_number, 'thin', 3000) }.should raise_error(ArgumentError)
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
  
  it 'should absolutize file path' do
    @cluster.pid_file_for(3000).should == File.expand_path(File.dirname(__FILE__) + "/rails_app/thin.3000.pid")
  end
  
  it 'should start on specified port' do
    @cluster.start_on_port 3000
    
    File.exist?(@cluster.pid_file_for(3000)).should be_true
    File.exist?(@cluster.log_file_for(3000)).should be_true
  end

  it 'should stop on specified port' do
    @cluster.start_on_port 3000
    @cluster.stop_on_port 3000
    
    File.exist?(@cluster.pid_file_for(3000)).should be_false
  end
  
  after do
    3000.upto(3003) do |port|
      Process.kill 9, @cluster.pid_for(port) rescue nil
      File.delete @cluster.pid_file_for(port) rescue nil
      File.delete @cluster.log_file_for(port) rescue nil
    end
  end
end