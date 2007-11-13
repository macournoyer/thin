require File.dirname(__FILE__) + '/test_helper'

class RequestTest < Test::Unit::TestCase
  def test_outputs_headers
    response = Fart::Response.new
    response.content_type = 'text/html'
    response.headers['Cookie'] = 'mium=7'
    
    assert_equal "Content-Type: text/html\r\nConnection: close\r\nContent-Length: 0\r\nCookie: mium=7\r\n", response.headers_output
  end
  
  def test_outputs_head
    response = Fart::Response.new
    response.content_type = 'text/html'
    response.headers['Cookie'] = 'mium=7'
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: 0\r\nCookie: mium=7\r\n\r\n", response.head
  end
  
  def test_outputs_body
    response = Fart::Response.new
    response.content_type = 'text/html'
    response.body << '<html></html>'
    
    output = StringIO.new
    response.write output
    output.rewind
    
    assert_equal "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: 13\r\n\r\n<html></html>", output.read
  end
  
  def test_perfs
    response = Fart::Response.new
    response.content_type = 'text/html'
    response.body << <<-EOS
<html><head><title>Dir listing</title></head>
<body><h1>Listing stuff</h1><ul>
#{'<li>Hi!</li>' * 100}
</ul></body></html>
EOS
    
    Benchmark.bm do |x|
      x.report('baseline') { response.body.rewind; response.body.read }
      x.report('   parse') { response.write StringIO.new }
    end
    #        user       system     total       real
    # parse  0.000000   0.000000   0.000000 (  0.000037)
  end
end