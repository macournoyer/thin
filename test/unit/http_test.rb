require 'test_helper'
require 'thin/protocols/http'

class HttpTest < Test::Unit::TestCase
  def setup
    @connection = Thin::Protocols::Http.new(nil)
    @connection.server = self
    @connection.post_init

    @connection.stubs(:send_data)
    @connection.stubs(:close_connection_after_writing)
    @connection.stubs(:socket_address).returns("127.0.0.1")
  end

  def app
    proc do |env|
      [200, {"Content-Type" => "text/plain"}, ["ok"]]
    end
  end

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

  def test_parse_request
    request = <<-EOS
GET /path?yo=dude HTTP/1.1
Host: localhost:3000

EOS

    @connection.receive_data(request)

    assert_equal "GET", @connection.request.env["REQUEST_METHOD"]
    assert_equal "/path", @connection.request.env["PATH_INFO"]
    assert_equal "yo=dude", @connection.request.env["QUERY_STRING"]
    assert_equal "localhost:3000", @connection.request.env["HTTP_HOST"]
  end
  
  def test_async_response_do_not_send_response
    @connection.expects(:send_response).never
    
    @connection.process(Thin::Protocols::Http::AsyncResponse)
  end
end
