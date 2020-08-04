require 'spec_helper'

require 'timeout'

class TestServer
  include Logging
  include Daemonizable

  def stop
  end

  def name
    'Thin test server'
  end
end

describe 'Daemonizing' do
  let(:path) {File.expand_path("tmp", __dir__)}
  let(:log_file) {File.expand_path("test_server.log", path)}
  let(:pid_file) {File.expand_path("test.pid", path)}

  before do
    FileUtils.rm_rf path
    FileUtils.mkpath path
    FileUtils.touch log_file
  end

  subject(:server) do
    TestServer.new.tap do |server|
      server.log_file = log_file
      server.pid_file = pid_file
    end
  end

  it 'should have a pid file' do
    subject.should respond_to(:pid_file)
    subject.should respond_to(:pid_file=)
  end

  it 'should create a pid file' do
    fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    subject.kill
  end
  
  it 'should redirect stdio to a log file' do
    pid = fork do
      subject.daemonize

      puts "simple puts"
      STDERR.puts "STDERR.puts"
      STDOUT.puts "STDOUT.puts"

      sleep
    end

    wait_for_server_to_start

    log = File.read(log_file)
    log.should include('simple puts', 'STDERR.puts', 'STDOUT.puts')

    server.kill
  end
  
  it 'should change privilege' do
    pid = fork do
      subject.daemonize
      subject.change_privilege('root', 'admin')
    end

    _, status = Process.wait2(pid)

    status.should be_a_success
  end
  
  it 'should kill process in pid file' do
    File.exist?(subject.pid_file).should be_falsey

    fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    File.exist?(subject.pid_file).should be_truthy

    silence_stream STDOUT do
      subject.kill(1)
    end

    File.exist?(subject.pid_file).should be_falsey
  end
  
  it 'should force kill process in pid file' do
    fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    subject.kill(0)

    File.exist?(subject.pid_file).should be_falsey
  end
  
  it 'should send kill signal if timeout' do
    fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    pid = subject.pid

    subject.kill(1)

    File.exist?(subject.pid_file).should be_falsey
    Process.running?(pid).should be_falsey
  end
  
  it "should restart" do
    fork do
      subject.on_restart {}
      subject.daemonize
      sleep 5
    end

    wait_for_server_to_start

    silence_stream STDOUT do
      TestServer.restart(subject.pid_file)
    end

    proc { sleep 0.1 while File.exist?(subject.pid_file) }.should take_less_then(20)
  end
  
  it "should ignore if no restart block specified" do
    subject.restart
  end
  
  it "should not restart when not running" do
    silence_stream STDOUT do
      subject.restart
    end
  end
  
  it "should exit and raise if pid file already exist" do
    fork do
      subject.daemonize
      sleep 5
    end

    wait_for_server_to_start

    proc { subject.daemonize }.should raise_error(PidFileExist)

    File.exist?(subject.pid_file).should be_truthy
  end

  it "should raise if no pid file" do
    proc do
      TestServer.kill("donotexist", 0)
    end.should raise_error(PidFileNotFound)
  end

  it "should should delete pid file if stale" do
    # Create a file w/ a PID that does not exist
    File.open(subject.pid_file, 'w') { |f| f << 999999999 }
    
    subject.send(:remove_stale_pid_file)
    
    File.exist?(subject.pid_file).should be_falsey
  end

  private

  def wait_for_server_to_start
    proc{sleep 0.1 until File.exist?(subject.pid_file)}.should take_less_then(10)
  end
end
