require 'test_helper'
require 'thin/connection'

class ConnectionTest < Test::Unit::TestCase
  def setup
    @connection = Thin::Connection.new(nil)
    @connection.server = self
    @connection.post_init

    @connection.stubs(:send_data)
    @connection.stubs(:close_connection_after_writing)
    @connection.stubs(:socket_address).returns("127.0.0.1")
  end

  #### Server methods
  def app
    proc do |env|
      [200, {"Content-Type" => "text/plain"}, ["ok"]]
    end
  end
  def threaded?; false end
  def prefork?; false end
  ####

  def teardown
    @connection.unbind
  end

  def test_send_response_body
    request = <<-EOS
GET / HTTP/1.1
Host: localhost:3000

EOS

    @connection.expects(:send_data).with(includes("Content-Type: text/plain"))
    @connection.expects(:send_data).with("ok")
    @connection.expects(:close_connection_after_writing).once

    @connection.receive_data(request)
  end

  def test_parse_get_request
    request = <<-EOS
GET /path?yo=dude HTTP/1.1
Host: localhost:3000
X-Special: awesome

EOS

    @connection.expects(:process)
    @connection.receive_data(request)
    
    env = @connection.request.env
    
    assert_equal "GET", env["REQUEST_METHOD"]
    assert_equal "/path", env["PATH_INFO"]
    assert_equal "HTTP/1.1", env["SERVER_PROTOCOL"]
    assert_equal "HTTP/1.1", env["HTTP_VERSION"]
    assert_equal "yo=dude", env["QUERY_STRING"]
    assert_equal "localhost:3000", env["HTTP_HOST"]
    assert_equal "awesome", env["HTTP_X_SPECIAL"]
    
    # rack. values
    assert_respond_to env["rack.input"], :read
    assert_equal "http", env["rack.url_scheme"]
  end
  
  def test_parse_post_request
    request = <<-EOS
POST /path HTTP/1.1
Host: localhost:3000
Content-Type: text/plain
Content-Length: 2

hi
EOS

    @connection.expects(:process)
    @connection.receive_data(request)
    
    env = @connection.request.env
    
    assert_equal "POST", env["REQUEST_METHOD"]
    assert_equal "/path", env["PATH_INFO"]
    assert_equal "hi", env["rack.input"].read
  end
  
  def test_parse_duplicate_headers
    request = <<-EOS
GET / HTTP/1.1
Content-Type: text/plain
Content-Type: charset=utf8

EOS

    @connection.expects(:process)
    @connection.receive_data(request)

    env = @connection.request.env

    assert_equal "text/plain, charset=utf8", env["CONTENT_TYPE"]
  end
  
  def test_defered_response_do_not_send
    @connection.expects(:write).never
    
    @connection.send_response([200, {'X-Thin-Defer' => 'yes'}, []])
  end
end
