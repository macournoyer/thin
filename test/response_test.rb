require File.dirname(__FILE__) + '/test_helper'

class RequestTest < Test::Unit::TestCase
  def test_outputs_headers
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.headers['Cookie'] = 'mium=7'
    
    assert_equal "Content-Type: text/html\r\nConnection: close\r\nContent-Length: 0\r\nCookie: mium=7\r\n", response.headers_output
  end
  
  def test_outputs_head
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.headers['Cookie'] = 'mium=7'
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: 0\r\nCookie: mium=7\r\n\r\n", response.head
  end
  
  def test_outputs_body
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.body << '<html></html>'
    
    output = StringIO.new
    response.write output
    output.rewind
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: 13\r\n\r\n<html></html>", output.read
  end
  
  def test_perfs
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.body << <<-EOS
<html><head><title>Dir listing</title></head>
<body><h1>Listing stuff</h1><ul>
#{'<li>Hi!</li>' * 100}
</ul></body></html>
EOS
    
    max_time = 0.000040 # sec
    time = Benchmark.measure { response.write StringIO.new }
    assert time.real <= max_time, "Response writing too slow : took #{time.real*1000} ms, should take less then #{max_time*1000} ms"
    
    # Perf history
    # 1) 0.000037
  end
end