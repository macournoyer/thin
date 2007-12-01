require File.dirname(__FILE__) + '/test_helper'

class HeadersTest < Test::Unit::TestCase
  def setup
    @headers = Thin::Headers.new
  end
  
  def test_allow_duplicate_on_some_fields
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    assert_equal 2, @headers.size
  end
  
  def test_non_duplicate_overwrites_value
    @headers['Host'] = 'this is unique'
    @headers['Host'] = 'so is this'
    @headers['Host'] = 'so this will overwrite ^'

    assert_equal 'so this will overwrite ^', @headers['Host']
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