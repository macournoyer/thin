require 'test_helper'

class WorkerTest < IntegrationTestCase
  def test_crash
    get "/crash"
    
    assert_status 500
  end
  
  def test_restart_worker_on_exit
    get "/exit" rescue EOFError
    get "/"
    
    assert_status 200
  end
end