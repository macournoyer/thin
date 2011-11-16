require 'test_helper'

class RobustnessTest < IntegrationTestCase
  def test_should_not_crash_when_header_too_large
    thin
    
    100.times do
      begin
        socket = TCPSocket.new("localhost", PORT)
        socket.write("GET / HTTP/1.1\r\n")
        socket.write("Host: localhost\r\n")
        socket.write("Connection: close\r\n")
        10000.times do
          socket.write("X-Foo: #{'x' * 100}\r\n")
          socket.flush
        end
        socket.write("\r\n")
        socket.read
        socket.close
      rescue Errno::EPIPE, Errno::ECONNRESET
        # Ignore.
      end
    end
  end
  
  def test_incomplete_request
    thin :timeout => 1
    
    request "GET /?this HTTP/1.1\r\nHost:"
    
    assert_status 200
  end
end