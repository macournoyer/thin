require File.dirname(__FILE__) + '/test_helper'

class HeadersTest < Test::Unit::TestCase
  def setup
    @headers = Thin::Headers.new
  end
  
  def test_allow_duplicate
    @headers['Host'] = 'this is unique'
    @headers['Host'] = 'so this will overwrite ^'
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    assert_equal 3, @headers.size
  end
  
  def test_reader
    @headers['Set-Cookie'] = 'hi'
    assert_equal 'hi', @headers['Set-Cookie']
  end
  
  def test_to_s
    @headers['Host'] = 'localhost:3000'
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    assert_equal "Host: localhost:3000\r\nSet-Cookie: twice\r\nSet-Cookie: is cooler the once\r\n", @headers.to_s
  end
end