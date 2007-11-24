require File.dirname(__FILE__) + '/test_helper'
require 'timeout'

class DaemonizerTest < Test::Unit::TestCase
  def setup
    @daemonizer = Thin::Daemonizer.new('thin.pid')
  end
  
  def test_daemonize
    @daemonizer.daemonize do
      assert File.exist?('thin.pid')
    end
    
    assert !File.exist?('thin.pid')
  end
  
  def test_kill
    @daemonizer.daemonize { empty_loop }
    
    Timeout.timeout(10) do
      sleep 0.5 until File.exist?('thin.pid')
    end
    
    @daemonizer.kill
    
    assert !File.exist?('thin.pid')
  end
  
  def test_send_kill_signal_if_timeout
    @daemonizer.timeout = 1
    @daemonizer.daemonize do
      trap('INT') {} # pretend we cannot handle INT signal
      loop {}
    end
    
    Timeout.timeout(10) do
      sleep 0.5 until File.exist?('thin.pid')
    end
    
    @daemonizer.kill
    
    assert !File.exist?('thin.pid')
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