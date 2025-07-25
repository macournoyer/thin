require 'spec_helper'

require 'timeout'
require "tmpdir"

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
  let(:log_file) {File.join(@root, "test_server.log")}
  let(:pid_file) {File.join(@root, "test.pid")}

  around do |example|
    Dir.mktmpdir do |root|
      @root = root

      # Ensure the log file exists with the correct permissions:
      File.open(log_file, "w+") {}

      example.run
      @root = nil
    end
  end

  subject(:server) do
    raise "No root directory" unless @root

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
    expect(log).to include('simple puts', 'STDERR.puts', 'STDOUT.puts')

    server.kill
  end
  
  it 'should change privilege' do
    pid = fork do
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

    Process.wait(pid)
    expect(File.exist?(subject.pid_file)).to be_falsey
  end
  
  it 'should force kill process in pid file' do
    fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    subject.kill(0)

    expect(File.exist?(subject.pid_file)).to be_falsey
  end
  
  it 'should send kill signal if timeout' do
    fork do
      subject.daemonize
      sleep
    end

    wait_for_server_to_start

    pid = subject.pid

    subject.kill(10)

    expect(File.exist?(subject.pid_file)).to be_falsey
    expect(Process.running?(pid)).to be_falsey
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

    expect { sleep 0.1 while File.exist?(subject.pid_file) }.to take_less_then(20)
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

    expect { subject.daemonize }.to raise_error(PidFileExist)

    expect(File.exist?(subject.pid_file)).to be_truthy
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
    count = 1
    
    while true
      break if File.exist?(subject.pid_file)

      sleep(count * 0.1)

      if count > 10
        $stderr.puts "Dumping log file #{subject.log_file}:"
        File.foreach(subject.log_file) do |line|
          $stderr.puts line
        end

        raise "Server did not start"
      end

      count += 1
    end
  end
end
