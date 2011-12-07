require 'test_helper'

class WorkerTest < IntegrationTestCase
  def test_restart_worker_on_exit
    thin do
      worker_processes 1
    end

    assert_raise(EOFError) { get "/exit" }
    get "/"

    assert_status 200
  end

  def test_timeout
    thin do
      timeout 1
    end

    assert_raise(EOFError) { get "/sleep?sec=2" }
  end
end
