require File.dirname(__FILE__) + '/test_helper'

class TestHandler < Thin::Handler
  def process(request, response)
    response.body << request.body.read
    response.body << request.params['QUERY_STRING']
    true
  end
end

class ServerUnitTest < Test::Unit::TestCase
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
    request "GET / HTTP/1.1\n\rHost: localhost:3000\n\rContent-Length: 12\n\r\n\rmore cowbell"
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
      @client = StringIO.new('not-empty')
      @socket.stubs(:accept).returns(@client)
      @socket.stubs(:closed?).returns(false).then.returns(true)
      
      @client.stubs(:readpartial).returns(body).then.returns(nil)
      @client.stubs(:peeraddr).returns([])
      @client.stubs(:close)
    end
      
    def assert_response(body, options={})
      status = options.delete(:status) || 200
      @client.rewind
      response = @client.read
      assert_match "HTTP/1.1 #{status} #{Thin::HTTP_STATUS_CODES[status]}", response
      assert_match body, response
    end
end

class ServerFunctionalTest < Test::Unit::TestCase
  def setup
    @daemonizer = Thin::Daemonizer.new('server_test.pid')
    @daemonizer.daemonize('test server') do
      server = Thin::Server.new('0.0.0.0', 3333, TestHandler.new)
      server.logger = Logger.new(nil)
      server.start
    end
  end
  
  def teardown
    @daemonizer.kill
  end
  
  def test_get
    assert_equal 'cthis', get('/?cthis')
  end
  
  def test_post
    assert_equal 'arg=pirate', post('/', :arg => 'pirate')
  end
  
  # Raises Errno::EPIPE: Broken pipe
  # def test_big_post
  #   big = 'yo-fatty' * Thin::CHUNK_SIZE * 2
  #   assert_equal big.size+4, post('/', :big => big).size
  # end
  
  private
    def get(url)
      Net::HTTP.get(URI.parse('http://0.0.0.0:3333' + url))
    end
    
    def post(url, params={})
      Net::HTTP.post_form(URI.parse('http://0.0.0.0:3333' + url), params).body
    end
end