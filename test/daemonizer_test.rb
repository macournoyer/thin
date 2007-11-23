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
    
    Timeout.timeout(5) do
      sleep 0.5 until File.exist?('thin.pid')
    end
    
    @daemonizer.kill
    
    assert !File.exist?('thin.pid')
  end
  
  private
    def empty_loop
      begin
        loop {}
      rescue Exception => e
        # Ignore interupt error
      end
    end
end