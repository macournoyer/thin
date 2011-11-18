require 'test_helper'

class RobustnessTest < IntegrationTestCase
  def test_should_not_crash_when_header_too_large
    thin :log => "/dev/null"
    
    100.times do
      begin
        socket do |s|
          s.write("GET / HTTP/1.1\r\n")
          s.write("Host: localhost\r\n")
          s.write("Connection: close\r\n")
          10000.times do
            s.write("X-Foo: #{'x' * 100}\r\n")
            s.flush
          end
          s.write("\r\n")
          s.read
        end
      rescue Errno::EPIPE, Errno::ECONNRESET
        # Ignore.
      end
    end
  end
  
  def test_incomplete_request
    thin :timeout => 1
    
    socket do |s|
      s.write "GET /?this HTTP/1.1\r\n"
      s.write "Host:"
      assert_equal "", s.read
    end
  end
end