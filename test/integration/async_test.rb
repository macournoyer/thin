require 'test_helper'

class AsyncTest < IntegrationTestCase
  def test_get
    thin :env => "none"
    
    socket do |s|
      s.write("GET /async HTTP/1.1\r\n")
      s.write("\r\n")
      s.flush
      
      assert_match "HTTP/1.1 200 OK", s.readpartial(1024)
      assert_equal "1\n", s.readpartial(10)
      sleep 0.1
      assert_equal "2\n", s.readpartial(10)
    end
  end
end
