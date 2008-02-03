require File.dirname(__FILE__) + '/spec_helper'

class TestServer
  include Logging # Daemonizable should include this?
  include Daemonizable
  
  def stop
  end
  
  def name
    'thin'
  end
end

describe 'Daemonizing' do
  
  before(:all) do
    @logfile = File.dirname(__FILE__) + '/../log/daemonizing_test.log'
    File.delete(@logfile) if File.exist?(@logfile)
    @child_processes = []
  end
  
  before(:each) do
    @server = TestServer.new
    @server.log_file = @logfile
    @server.pid_file = 'test.pid'
    @pid = nil
  end
  
  it 'should have a pid file' do
    @server.should respond_to(:pid_file)
    @server.should respond_to(:pid_file=)
  end
  
  it 'should create a pid file' do
    @pid = fork do
      @child_processes << Process.pid
      @server.daemonize
      sleep 1
    end
    
    sleep 1
    Process.wait(@pid)
    File.exist?(@server.pid_file).should be_true
    @pid = @server.pid

    proc { sleep 0.1 while File.exist?(@server.pid_file) }.should take_less_then(5)
  end
  
  it 'should redirect stdio to a log file' do
    @pid = fork do
      @child_processes << Process.pid
      @server.log_file = 'daemon_test.log'
      @server.daemonize

      puts "simple puts"
      STDERR.puts "STDERR.puts"
      STDOUT.puts "STDOUT.puts"
    end
    Process.wait(@pid)
    # Wait for the file to close and magical stuff to happen
    proc { sleep 0.1 until File.exist?('daemon_test.log') }.should take_less_then(3)
    sleep 0.5

    log = File.read('daemon_test.log')
    log.should include('simple puts', 'STDERR.puts', 'STDOUT.puts')
    
    File.delete 'daemon_test.log'
  end
  
  it 'should change privilege' do
    @pid = fork do
      @child_processes << Process.pid
      @server.daemonize
      @server.change_privilege('root', 'admin')
    end
    Process.wait(@pid)
    $?.should be_a_success
  end
  
  it 'should kill process in pid file' do
    @pid = fork do
      @child_processes << Process.pid
      @server.daemonize
      loop { sleep 1 }
    end
  
    server_should_start_in_less_then 3
  
    silence_stream STDOUT do
      Server.kill(@server.pid_file, 1)
    end
  
    File.exist?(@server.pid_file).should_not be_true
  end
  
  it 'should send kill signal if timeout' do
    @pid = fork do
      @child_processes << Process.pid
      @server.should_receive(:stop) # pretend we cannot handle the INT signal
      @server.daemonize
      sleep 5
    end
  
    server_should_start_in_less_then 10
  
    silence_stream STDOUT do
      Server.kill(@server.pid_file, 1)
    end
  
    File.exist?(@server.pid_file).should be_false
    Process.running?(@pid).should be_false
  end
  
  it "should restart" do
    @pid = fork do
      @child_processes << Process.pid
      @server.on_restart {}
      @server.daemonize
      sleep 5
    end
    
    server_should_start_in_less_then 10
  
    silence_stream STDOUT do
      Server.restart(@server.pid_file)
    end
    
    proc { sleep 0.1 while File.exist?(@server.pid_file) }.should take_less_then(10)
  end
  
  it "should exit if pid file already exist" do
    @pid = fork do
      @child_processes << Process.pid
      @server.daemonize
      sleep 5
    end
    server_should_start_in_less_then 10

    proc { @server.daemonize }.should raise_error(PidFileExist)
    
    File.exist?(@server.pid_file).should be_true
  end
  
  after(:each) do
    Process.kill(9, @pid.to_i) if @pid && Process.running?(@pid.to_i)
    Process.kill(9, @server.pid) if @server.pid && Process.running?(@server.pid)
    File.delete(@server.pid_file) rescue nil
  end
  
  after(:all) do
    @child_processes.each do |pid|
      Process.kill(9, pid) rescue nil
    end
  end
  
  private
    def server_should_start_in_less_then(sec=10)
      proc { sleep 0.1 until File.exist?(@server.pid_file) }.should take_less_then(10)
    end
end