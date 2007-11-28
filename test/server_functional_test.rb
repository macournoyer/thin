require File.dirname(__FILE__) + '/test_helper'

class ServerFunctionalTest < Test::Unit::TestCase
  def setup
    @daemonizer = Thin::Daemonizer.new('server_test.pid')
    @daemonizer.daemonize('test server') do
      server = Thin::Server.new('0.0.0.0', 3333, TestHandler.new)
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
  
  def test_big_post
    big = 'X' * Thin::CHUNK_SIZE * 2
    assert_equal big.size+4, post('/', :big => big).size
  end
  
  def test_get_perf
    assert_faster_then 5 do
      get('/')
    end
  end
  
  def test_post_perf
    assert_faster_then 5 do
      post('/', :file => 'X' * 1000)
    end
  end
  
  private
    def get(url)
      Net::HTTP.get(URI.parse('http://0.0.0.0:3333' + url))
    end
    
    def post(url, params={})
      Net::HTTP.post_form(URI.parse('http://0.0.0.0:3333' + url), params).body
    end
end