require File.dirname(__FILE__) + '/test_helper'

# FIXME!
class ServerTest < Test::Unit::TestCase
  def setup
    @handler = TestHandler.new
    
    @socket = stub_everything
    TCPServer.stubs(:new).returns(@socket)
    
    @server = Thin::Server.new('0.0.0.0', 3000, @handler)
    @server.logger = Logger.new(nil)
  end
  
  def test_ok
    request "GET / HTTP/1.1\n\rHost: localhost:3000"
    @server.start
    
    assert_response '', :status => 200
  end
  
  def test_bad_request
    request "FUCKED / STUFF/1.1\n\rnononon"
    @server.start
    
    assert_response 'Bad request', :status => 400
  end
  
  def test_not_found
    @handler.stubs(:process).returns(false)
    request "GET / HTTP/1.1\n\rHost: localhost:3000"
    @server.start
    
    assert_response 'Page not found', :status => 404    
  end
  
  def test_ok_with_body
    request "POST / HTTP/1.1\n\rHost: localhost:3000\n\rContent-Length: 12\n\r\n\rmore cowbell"
    @server.start
    
    assert_response 'more cowbell', :status => 200
  end
  
  def test_invalid_content_length
    request "GET / HTTP/1.1\n\rHost: localhost:3000\n\rContent-Length: #{Thin::CHUNK_SIZE}\n\r\n\rmore cowbell"
    @server.start
    
    assert_response 'more cowbell', :status => 200
  end
  
  def test_stop
    @server.start
    @socket.expects(:close)
    @server.stop
  end
  
  private
    def request(body)
      @client = StringIO.new(body)
      @response = ''
      @socket.stubs(:accept).returns(@client)
      @socket.stubs(:closed?).returns(false).then.returns(true)
      
      @client.stubs(:peeraddr).returns([])
      
      @client.stubs(:<<).with { |o| @response << o }
    end
      
    def assert_response(body, options={})
      status = options.delete(:status) || 200
      assert_match "HTTP/1.1 #{status} #{Thin::HTTP_STATUS_CODES[status]}", @response
      assert_match body, @response
    end
end