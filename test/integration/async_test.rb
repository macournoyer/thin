require 'test_helper'

class AsyncTest < IntegrationTestCase
  def test_get
    thin :env => "none"
    
    socket do |s|
      s.write("GET /async HTTP/1.1\r\n")
      s.write("\r\n")
      s.flush
      
      term = "\r\n"
      assert_match "HTTP/1.1 200 OK", s.readpartial(1024)
      assert_equal "4#{term}one\n#{term}", s.readpartial(20)
      sleep 0.1
      assert_equal "4#{term}two\n#{term}" +
                   "0#{term}#{term}", s.readpartial(20)
    end
  end
  
  def test_get_without_chunked_encoding
    thin :env => "none"
    
    socket do |s|
      s.write("GET /async HTTP/1.0\r\n")
      s.write("\r\n")
      s.flush
      
      assert_match "HTTP/1.0 200 OK", s.readpartial(1024)
      assert_equal "one\n", s.readpartial(20)
      sleep 0.1
      assert_equal "two\n", s.readpartial(20)
    end
  end
end
