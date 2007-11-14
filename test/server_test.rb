require File.dirname(__FILE__) + '/test_helper'

class TestHandler < Thin::Handler
  def process(request, response)
    response.body << 'test body'
    true
  end
end

class ServerTest < Test::Unit::TestCase
  def setup
    @handler = TestHandler.new
    @server = Thin::Server.new('0.0.0.0', 3000, @handler)
    @socket = mock
    @server.instance_variable_set :@socket, @socket
  end
  
  def test_successful_run
    client = StringIO.new('no-empty')
    @socket.stubs(:accept).returns(client)
    @socket.stubs(:closed?).returns(false).then.returns(true)
    
    client.expects(:readpartial).returns(<<EOS)
GET / HTTP/1.1
Host: localhost:3000
EOS
    client.stubs(:peeraddr).returns([])
    client.expects(:close)
    
    @server.run
    
    client.rewind
    assert_equal <<EOS.chomp, client.read.delete("\r")
HTTP/1.1 200 OK
Connection: close
Content-Length: 9

test body
EOS
  end
end