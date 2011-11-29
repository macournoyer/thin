require 'test_helper'

class SingleProcessTest < IntegrationTestCase
  def test_stop_with_int_signal
    @pid = thin :workers => 0
    
    Process.kill "INT", @pid
    
    Process.wait @pid
    @pid = nil
  end
end