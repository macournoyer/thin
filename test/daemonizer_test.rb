require File.dirname(__FILE__) + '/test_helper'
require 'timeout'

class DaemonizerTest < Test::Unit::TestCase
  def setup
    @daemonizer = Thin::Daemonizer.new('thin.pid')
  end
  
  def test_daemonize
    @daemonizer.daemonize do
      assert File.exist?(@daemonizer.pid_file)
    end
    
    assert !File.exist?(@daemonizer.pid_file)
  end
  
  def test_kill
    @daemonizer.timeout = 10
    kill_sent = false
    pid = @daemonizer.daemonize do
      trap('KILL') { kill_sent = true } # Kill signal is sent when timeout
      empty_loop
    end
    
    Timeout.timeout(10) do
      sleep 0.5 until File.exist?(@daemonizer.pid_file)
    end
    
    @daemonizer.kill
    
    assert !kill_sent, 'KILL signal sent'
    assert !File.exist?(@daemonizer.pid_file)
  ensure
    Process.kill 9, pid rescue nil
  end
  
  def test_send_kill_signal_if_timeout
    @daemonizer.timeout = 1
    pid = @daemonizer.daemonize do
      trap('INT') {} # pretend we cannot handle INT signal
      loop {}
    end
    
    Timeout.timeout(10) do
      sleep 0.5 until File.exist?(@daemonizer.pid_file)
    end
    
    @daemonizer.kill
    
    assert !File.exist?(@daemonizer.pid_file)
  ensure
    Process.kill 9, pid rescue nil
  end
  
  private
    def empty_loop(sleep_time=0.1)
      begin
        loop { sleep sleep_time }
      rescue Exception => e
        # Ignore interupt error
      end
    end
end