require 'test_helper'

class DaemonizeTest < IntegrationTestCase
  def test_do_not_daemonize
    pid = thin
    
    assert_equal @pid, pid, "Launcher PID should be the same as master PID"
    Process.kill 0, @pid
    
    get "/"
    
    assert_status 200
  end
  
  def test_daemonize
    pid = thin :daemonize => true
    
    assert_not_equal @pid, pid, "Launcher PID should not be the same as master PID"
    Process.kill 0, pid
    Process.kill 0, @pid
    
    get "/"
    
    assert_status 200
  end
end