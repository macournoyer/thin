require 'test_helper'

class KeepAliveTest < IntegrationTestCase
  def test_enabled_by_default_on_http_1_1
    thin

    get '/'

    assert_status 200
    assert_header "Connection", "keep-alive"
  end
  
  def test_disabled_on_http_1_0
    thin

    socket do |s|
      s.write("GET / HTTP/1.0\r\n")
      s.write("\r\n")
      s.flush
      
      assert_match "Connection: close", s.readpartial(1024)
    end
  end
  
  def test_limited
    thin do
      keep_alive_requests 0
    end

    get '/'

    assert_status 200
    assert_header "Connection", "close"
  end
end
