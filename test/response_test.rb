require File.dirname(__FILE__) + '/test_helper'

class ResponseTest < Test::Unit::TestCase
  def test_outputs_headers
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.headers['Cookie'] = 'mium=7'
    
    assert_equal "Content-Type: text/html\r\nCookie: mium=7\r\nContent-Length: 0\r\nConnection: close\r\n", response.headers_output
  end
  
  def test_outputs_head
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.headers['Cookie'] = 'mium=7'
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nCookie: mium=7\r\nContent-Length: 0\r\nConnection: close\r\n\r\n", response.head
  end
  
  def test_allow_duplicates_in_headers
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.headers['Set-Cookie'] = 'mium=7'
    response.headers['Set-Cookie'] = 'hi=there'
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nSet-Cookie: mium=7\r\nSet-Cookie: hi=there\r\nContent-Length: 0\r\nConnection: close\r\n\r\n", response.head
  end
  
  def test_outputs_body
    response = Thin::Response.new
    response.content_type = 'text/html'
    response.body << '<html></html>'
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 13\r\nConnection: close\r\n\r\n<html></html>", response.to_s
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
    
    assert_faster_then 'Response writing', 0.040 do
      response.to_s
    end
    
    # Perf history
    # 1) 0.000037
  end
end