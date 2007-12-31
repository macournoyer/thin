require File.dirname(__FILE__) + '/spec_helper'

describe 'Daemonizing' do
  before do
    @server = Server.new('0.0.0.0', 3000, nil)
    @server.log_file = File.dirname(__FILE__) + '/../log/daemonizing_test.log'
    @server.pid_file = 'test.pid'
    @pid = nil
  end
  
  it 'should have a pid file' do
    @server.should respond_to(:pid_file)
    @server.should respond_to(:pid_file=)
  end
  
  it 'should create a pid file' do
    @pid = fork do
      @server.daemonize
      sleep 1
    end
    
    Process.wait(@pid)
    File.exist?(@server.pid_file).should be_true
    @pid = @server.pid

    proc { sleep 0.1 while File.exist?(@server.pid_file) }.should take_less_then(2)
  end
  
  it 'should redirect stdio to a log file' do
    @pid = fork do
      @server.log_file = 'daemon_test.log'

      @server.daemonize

      puts "simple puts"
      STDERR.puts "STDERR.puts"
      STDOUT.puts "STDOUT.puts"
    end
    Process.wait(@pid)
    sleep 0.1 # Wait for the file to close and magical stuff to happen
  
    log = File.read('daemon_test.log')
    log.should include('simple puts', 'STDERR.puts', 'STDOUT.puts')
  end
  
  it 'should change privilege' do
    @pid = fork do
      @server.daemonize
      @server.change_privilege('root', 'admin')
    end
    Process.wait(@pid)
    $?.should be_a_success
  end
  
  it 'should kill process in pid file' do
    @pid = fork do
      @server.daemonize
      loop { sleep 1 }
    end
  
    proc { sleep 0.1 until File.exist?(@server.pid_file) }.should take_less_then(3)
  
    silence_stream STDOUT do
      Server.kill(@server.pid_file, 1)
    end
  
    File.exist?(@server.pid_file).should_not be_true
  end
  
  it 'should send kill signal if timeout' do
    @pid = fork do
      @server.should_receive(:stop) # pretend we cannot handle the INT signal
      @server.daemonize
      sleep 5
    end
  
    proc { sleep 0.1 until File.exist?(@server.pid_file) }.should take_less_then(10)
  
    silence_stream STDOUT do
      Server.kill(@server.pid_file, 1)
    end
  
    File.exist?(@server.pid_file).should be_false
    Process.running?(@pid).should be_false
  end
  
  after do
    File.delete 'daemon_test.log' if File.exist?('daemon_test.log')
    Process.kill(9, @pid.to_i) if @pid && Process.running?(@pid.to_i)
  end
end