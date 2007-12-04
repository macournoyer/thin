require File.dirname(__FILE__) + '/test_helper'

class RailsTest < Test::Unit::TestCase
  def setup
    @handler = Thin::RailsHandler.new(File.dirname(__FILE__) + '/rails_app')
    @response = Thin::Response.new
    
    @handler.start
  end
  
  def test_do_not_handle_static_files
    assert_equal false, @handler.process(TestRequest.new('/favicon.ico'), @response)
  end
  
  def test_get_index
    assert @handler.process(TestRequest.new('/test'), @response)
    @response.body.rewind

    assert_equal <<EOS, @response.body.read
<h1>Test#index</h1>
<p>Find me in app/views/test/index.rhtml</p>
EOS
  end
  
  def test_perf
    assert_faster_then 'Rails process', 300 do
      @handler.process(TestRequest.new('/test'), @response)
    end
  end
end