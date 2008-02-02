require File.dirname(__FILE__) + '/spec_helper'

describe Runner do
  it "should parse options" do
    runner = Runner.new(%w(start --pid test.pid --port 5000))
    runner.parse!
    
    runner.options[:pid].should == 'test.pid'
    runner.options[:port].should == 5000
  end
  
  it "should parse specified command" do
    runner = Runner.new(%w(start))
    
    runner.parse!
    runner.command.should == 'start'
  end

  it "should abort on unknow command" do
    runner = Runner.new(%w(poop))
    
    runner.should_receive(:abort)
    runner.run!
  end
  
  it "should exit on empty command" do
    runner = Runner.new([])
    
    runner.should_receive(:exit).with(1)
    
    silence_stream(STDOUT) do
      runner.run!
    end
  end
  
  it "should change directory after loading config" do
    runner = Runner.new(%w(start --config spec/config.yml))
  
    Cluster.should_receive(:new).and_return(mock('controller', :null_object => true))
    expected_dir = File.expand_path('spec/rails_app')
    
    runner.run!
  
    Dir.pwd.should == expected_dir
  end
  
  it "should load options from file with :config option"
  
  it "should use controller when controlling a single server"

  it "should use cluster controller when controlling multiple servers"
  
  it "should consider as a cluster with :servers option"
  
  it "should consider as a cluster with :only option"
  
  it "should send command to controller"
end