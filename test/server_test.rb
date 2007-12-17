require File.dirname(__FILE__) + '/test_helper'

class ServerTest < Test::Unit::TestCase
  def setup
    app = proc do |env|
      body = [env['QUERY_STRING'], env['rack.input'].read].compact
      [200, { 'Content-Type' => 'text/html' }, body]
    end
    server = Thin::Server.new('0.0.0.0', 3333, app)
    server.timeout = 3
    server.silent = true # Remove this to get more details
    server.trace = true
    
    server.start
    @thread = Thread.new do
      server.listen!
    end
    sleep 0.1 until @thread.status == 'sleep'
  end
  
  def teardown
    @thread.kill
  end
  
  def test_get
    assert_equal 'cthis', get('/?cthis')
  end
  
  def test_raw_get
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 4\r\nConnection: close\r\n\r\nthis",
                 raw('0.0.0.0', 3333, "GET /?this HTTP/1.1\r\n\r\n")
  end
  
  def test_incomplete_headers
    assert_equal '', raw('0.0.0.0', 3333, "GET /?this HTTP/1.1\r\nHost:")
  end
  
  def test_incorrect_content_length
    assert_equal '', raw('0.0.0.0', 3333, "POST / HTTP/1.1\r\nContent-Length: 300\r\n\r\naye")
  end
  
  def test_post
    assert_equal 'arg=pirate', post('/', :arg => 'pirate')
  end
  
  def test_big_post
    big = 'X' * (20 * 1024)
    assert_equal big.size+4, post('/', :big => big).size
  end
  
  def test_get_perf
    assert_faster_then 'GET', 5 do
      get('/')
    end
  end
  
  def test_post_perf
    assert_faster_then 'POST', 6 do
      post('/', :file => 'X' * 1000)
    end
  end
  
  private
    def get(url)
      Net::HTTP.get(URI.parse('http://0.0.0.0:3333' + url))
    end
    
    def raw(host, port, data)
      socket = TCPSocket.new(host, port)
      socket.write data
      out = socket.read
      socket.close
      out
    end
    
    def post(url, params={})
      Net::HTTP.post_form(URI.parse('http://0.0.0.0:3333' + url), params).body
    end
end