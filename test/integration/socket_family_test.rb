require 'test_helper'

class SocketFamilyTest < IntegrationTestCase
  def test_ipv4
    thin do
      listen PORT
    end

    get "/"

    assert_status 200
    assert_response_equals "ok"
    assert_header "Content-Type", "text/html"
  end

  def test_ipv6
    thin do
      listen "[::]:#{PORT}"
    end

    get "/"

    assert_status 200
    assert_response_equals "ok"
    assert_header "Content-Type", "text/html"
  end

  def test_unix_socket
    thin do
      listen UNIX_SOCKET
    end

    unix_socket do |s|
      s.write "GET / HTTP/1.1\r\n\r\n"
      assert_match "HTTP/1.1 200 OK", s.read
    end
  end
end
