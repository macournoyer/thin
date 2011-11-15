require 'test_helper'

class RequestTest < Test::Unit::TestCase
  def setup
    @request = Thin::Request.new
  end
  
  def test_env_contains_requires_rack_variables
    assert_respond_to @request.env['rack.input'], :read
    assert_kind_of IO, @request.env['rack.errors']
    assert_equal [1, 1], @request.env['rack.version']
  end
  
  def test_convert_parser_headers_to_rack_env
    @request.headers = {
      "Host" => "localhost:9292",
      "Connection" => "close"
    }
    
    assert_equal "localhost:9292", @request.env["HTTP_HOST"]
    assert_equal "close", @request.env["HTTP_CONNECTION"]
    assert ! @request.env.key?("HOST")
    assert ! @request.env.key?("CONNECTION")
  end
  
  def test_do_not_prefix_content_length
    @request.headers = {
      "Content-Type" => "text/html"
    }
    
    assert ! @request.env.key?("HTTP_CONTENT_TYPE")
    assert_equal "text/html", @request.env["CONTENT_TYPE"]
  end
end