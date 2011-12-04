require 'test_helper'

class SingleProcessTest < IntegrationTestCase
  def test_stop_with_int_signal
    thin :workers => 0
    
    Process.kill "INT", @pid
    _, status = Process.wait2 @pid
    @pid = nil
    
    assert status.success?
  end
end