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
    expect(subject).to respond_to(:pid_file)
    expect(subject).to respond_to(:pid_file=)
  end

  it 'should create a pid file' do
    pid = fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    subject.kill
    Process.wait(pid)
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
    expect(log).to include('simple puts', 'STDERR.puts', 'STDOUT.puts')

    server.kill
    Process.wait(pid)
  end
  
  it 'should change privilege' do
    pid = fork do
      subject.daemonize
      subject.change_privilege('root', 'admin')
    end

    _, status = Process.wait2(pid)
    expect(status).to be_a_success
  end
  
  it 'should kill process in pid file' do
    expect(File.exist?(subject.pid_file)).to be_falsey

    pid = fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    expect(File.exist?(subject.pid_file)).to be_truthy

    silence_stream STDOUT do
      subject.kill(1)
    end

    Process.kill(:INT, pid)
    Process.wait(pid)

    expect(File.exist?(subject.pid_file)).to be_falsey
  end
  
  it 'should force kill process in pid file' do
    pid = fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    subject.kill(0)

    Process.wait(pid)
    expect(File.exist?(subject.pid_file)).to be_falsey
  end
  
  it 'should send kill signal if timeout' do
    pid = fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    server_pid = subject.pid

    subject.kill(10)
    Process.wait(pid)

    expect(File.exist?(subject.pid_file)).to be_falsey
    expect(Process.running?(server_pid)).to be_falsey
  end
  
  it "should restart" do
    pid = fork do
      subject.on_restart {}
      subject.daemonize
      sleep 5
    end

    wait_for_server_to_start

    silence_stream STDOUT do
      TestServer.restart(subject.pid_file)
    end

    Process.wait(pid)
    expect(File.exist?(subject.pid_file)).to be_falsey
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
    pid = fork do
      subject.daemonize
      sleep 5
    end

    wait_for_server_to_start

    expect { subject.daemonize }.to raise_error(PidFileExist)

    expect(File.exist?(subject.pid_file)).to be_truthy

    subject.kill
    Process.wait(pid)
  end

  it "should raise if no pid file" do
    expect do
      TestServer.kill("donotexist", 0)
    end.to raise_error(PidFileNotFound)
  end

  it "should should delete pid file if stale" do
    # Create a file w/ a PID that does not exist
    File.open(subject.pid_file, 'w') { |f| f << 999999999 }
    
    subject.send(:remove_stale_pid_file)
    
    expect(File.exist?(subject.pid_file)).to be_falsey
  end

  private

  def wait_for_server_to_start
    until File.exist?(subject.pid_file)
      sleep(0.1)
    end
  end
end
