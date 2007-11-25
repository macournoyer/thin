require File.dirname(__FILE__) + '/test_helper'

class RequestTest < Test::Unit::TestCase
  def test_parse_simple
    request = Thin::Request.new('GET / HTTP/1.1')
    assert_equal 'GET', request.verb
    assert_equal '/', request.path
    assert_equal 'HTTP/1.1', request.params['SERVER_PROTOCOL']
    assert_equal '/', request.params['REQUEST_PATH']
    assert_equal 'HTTP/1.1', request.params['HTTP_VERSION']
    assert_equal '/', request.params['REQUEST_URI']
    assert_equal 'CGI/1.2', request.params['GATEWAY_INTERFACE']
    assert_equal 'GET', request.params['REQUEST_METHOD']    
    assert_nil request.params['FRAGMENT']
    assert_nil request.params['QUERY_STRING']
  end
  
  def test_parse_error
    assert_raise(Thin::InvalidRequest) do
      Thin::Request.new("GET / SsUTF/1.1")
    end
    assert_raise(Thin::InvalidRequest) do
      Thin::Request.new("GET / HTTP/1.1\r\nyousmelllikecheeze")
    end
  end
  
  def test_fragment_in_uri
    request = Thin::Request.new("GET /forums/1/topics/2375?page=1#posts-17408 HTTP/1.1\r\n\r\n")

    assert_equal '/forums/1/topics/2375?page=1', request.params['REQUEST_URI']
    assert_equal 'posts-17408', request.params['FRAGMENT']
  end
  
  def test_parse_path_with_query_string
    request = Thin::Request.new('GET /index.html?234235 HTTP/1.1')
    assert_equal 'GET', request.verb
    assert_equal '/index.html', request.path
    assert_equal '234235', request.params['QUERY_STRING']
    assert_nil request.params['FRAGMENT']
  end
  
  def test_horrible_queries
    # test that large header names are caught
    assert_raises Thin::InvalidRequest do
      Thin::Request.new("GET /#{rand_data(10,120)} HTTP/1.1\r\nX-#{rand_data(1024, 1024+(1024))}: Test\r\n\r\n")
    end

    # test that large mangled field values are caught
    assert_raises Thin::InvalidRequest do
      get = "GET /#{rand_data(10,120)} HTTP/1.1\r\nX-Test: #{rand_data(1024, 80*1024+(1024), false)}\r\n\r\n"
      Thin::Request.new(get)
    end
    
    get = "GET /#{rand_data(10,120)} HTTP/1.1\r\n"
    get << "X-Test: test\r\n" * (80 * 1024)
    assert_raises Thin::InvalidRequest do
      Thin::Request.new(get)
    end

    # finally just that random garbage gets blocked all the time
    get = "GET #{rand_data(1024, 1024+(1024), false)} #{rand_data(1024, 1024+(1024), false)}\r\n\r\n"
    assert_raises Thin::InvalidRequest do
      Thin::Request.new(get)
    end
  end
  
  def test_parse_headers
    request = Thin::Request.new(<<-EOS)
GET / HTTP/1.1
Host: localhost:3000
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Cookie: mium=7
Keep-Alive: 300
Connection: keep-alive
EOS
    assert_equal 'localhost:3000', request.params['HTTP_HOST']
    assert_equal 'mium=7', request.params['HTTP_COOKIE']
  end
  
  def test_parse_headers_with_query_string
    request = Thin::Request.new(<<-EOS)
GET /page?cool=thing HTTP/1.1
Host: localhost:3000
Keep-Alive: 300
Connection: keep-alive
EOS
    assert_equal 'cool=thing', request.params['QUERY_STRING']
    assert_equal '/page?cool=thing', request.params['REQUEST_URI']
    assert_equal '/page', request.path
  end
  
  def test_parse_post_data
    request = Thin::Request.new(<<-EOS.chomp)
POST /postit HTTP/1.1
Host: localhost:3000
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Keep-Alive: 300
Connection: keep-alive
Content-Type: text/html
Content-Length: 37

name=marc&email=macournoyer@gmail.com
EOS

    assert_equal 'POST', request.params['REQUEST_METHOD']
    assert_equal '/postit', request.params['REQUEST_URI']
    assert_equal 'text/html', request.params['CONTENT_TYPE']
    assert_equal '37', request.params['CONTENT_LENGTH']
    assert_equal 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5', request.params['HTTP_ACCEPT']
    assert_equal 'en-us,en;q=0.5', request.params['HTTP_ACCEPT_LANGUAGE']
    assert_equal 'name=marc&email=macournoyer@gmail.com', request.params['RAW_POST_DATA']
    assert_equal 'name=marc&email=macournoyer@gmail.com', request.body.read
    assert_nil request.params['HTTP_CONTENT_LENGTH']
    assert_nil request.params['HTTP_CONTENT_TYPE']
  end
  
  def test_stupid_fucked_ie6_headers
    body = <<-EOS
POST /codes/58-tracking-file-downloads-automatically-in-google-analytics-with-prototype/refactors HTTP/1.0
X-Real-IP: 62.24.71.95
X-Forwarded-For: 62.24.71.95
Host: refactormycode.com
Connection: close
TE: deflate,gzip;q=0.3
Accept: */*
Range: bytes=0-499999
Referer: http://refactormycode.com/codes/58-tracking-file-downloads-automatically-in-google-analytics-with-prototype
User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)
Content-Length: 15771
Content-Type: application/x-www-form-urlencoded
Cookie: _refactormycode_session_id=a1b2n3jk4k5; flash=%7B%7D
Cookie2: $Version="1"
EOS
    request = Thin::Request.new(body)
    assert_equal '$Version="1"', request.params['HTTP_COOKIE2']
  end
  
  def test_parse_perfs
    body = <<-EOS.chomp
POST /postit HTTP/1.1
Host: localhost:3000
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Keep-Alive: 300
Connection: keep-alive
Content-Type: text/html
Content-Length: 37

hi=there#{'&name=marc&email=macournoyer@gmail.com'*1000}
EOS
    
    assert_faster_then 0.3 do
      Thin::Request.new(body)
    end

    # Perf history
    # 1) 0.379
    # 2) 0.21
  end
  
  private
    def rand_data(min, max, readable=true)
      count = min + ((rand(max)+1) *10).to_i
      res = count.to_s + "/"

      if readable
        res << Digest::SHA1.hexdigest(rand(count * 100).to_s) * (count / 40)
      else
        res << Digest::SHA1.digest(rand(count * 100).to_s) * (count / 20)
      end

      return res
    end
    
end