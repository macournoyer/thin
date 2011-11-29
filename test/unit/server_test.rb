require 'test_helper'

class ServerTest < Test::Unit::TestCase
  def setup
    app = proc { |env| [200, {}, ["ok"]] }
    @server = Thin::Server.new(app)
  end
  
  def test_pick_prefork_backend_if_any_workers
    @server.workers = 1
    assert_kind_of Thin::Backends::Prefork, @server.backend
  end
  
  def test_pick_single_process_backend_if_no_workers
    @server.workers = 0
    assert_kind_of Thin::Backends::SingleProcess, @server.backend
  end
  
  def test_cant_daemonize_single_process
    @server.workers = 0
    assert_raise(NotImplementedError) do
      silence_streams { @server.start(true) }
    end
  end
end