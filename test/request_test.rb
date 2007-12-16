require File.dirname(__FILE__) + '/test_helper'

class RequestTest < Test::Unit::TestCase
  def test_parse_simple
    request = R("GET / HTTP/1.1\r\n\r\n")
    assert_equal 'HTTP/1.1', request.env['SERVER_PROTOCOL']
    assert_equal '/', request.env['REQUEST_PATH']
    assert_equal 'HTTP/1.1', request.env['HTTP_VERSION']
    assert_equal '/', request.env['REQUEST_URI']
    assert_equal 'CGI/1.2', request.env['GATEWAY_INTERFACE']
    assert_equal 'GET', request.env['REQUEST_METHOD']    
    assert_equal '', request.env['FRAGMENT'].to_s
    assert_equal '', request.env['QUERY_STRING'].to_s
  end
  
  def test_parse_error
    assert_raise(Thin::InvalidRequest) do
      R("GET / SsUTF/1.1")
    end
    assert_raise(Thin::InvalidRequest) do
      R("GET / HTTP/1.1yousmelllikecheeze")
    end
  end
  
  def wtf_test_fragment_in_uri
    request = R("GET /forums/1/topics/2375?page=1#posts-17408 HTTP/1.1\r\n\r\n")

    assert_equal '/forums/1/topics/2375?page=1', request.env['REQUEST_URI']
    assert_equal 'posts-17408', request.env['FRAGMENT']
  end
  
  def test_parse_path_with_query_string
    request = R('GET /index.html?234235 HTTP/1.1')
    assert_equal '/index.html', request.env['REQUEST_PATH']
    assert_equal '234235', request.env['QUERY_STRING']
    assert_nil request.env['FRAGMENT']
  end
  
  def test_that_large_header_names_are_caught
    assert_raises Thin::InvalidRequest do
      R "GET /#{rand_data(10,120)} HTTP/1.1\r\nX-#{rand_data(1024, 1024+(1024))}: Test\r\n\r\n"
    end
  end

  def test_that_large_mangled_field_values_are_caught
    assert_raises Thin::InvalidRequest do
      R "GET /#{rand_data(10,120)} HTTP/1.1\r\nX-Test: #{rand_data(1024, 80*1024+(1024), false)}\r\n\r\n"
    end
  end
  
  def test_big_fat_ugly_headers
    get = "GET /#{rand_data(10,120)} HTTP/1.1\r\n"
    get << "X-Test: test\r\n" * (80 * 1024)
    assert_raises Thin::InvalidRequest do
      R(get)
    end    
  end

  def test_that_random_garbage_gets_blocked_all_the_time
    assert_raises Thin::InvalidRequest do
      R "GET #{rand_data(1024, 1024+(1024), false)} #{rand_data(1024, 1024+(1024), false)}\r\n\r\n"
    end
  end
  
  def test_parse_headers
    request = R(<<-EOS, true)
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
    assert_equal 'localhost:3000', request.env['HTTP_HOST']
    assert_equal 'mium=7', request.env['HTTP_COOKIE']
  end
  
  def test_parse_headers_with_query_string
    request = R(<<-EOS, true)
GET /page?cool=thing HTTP/1.1
Host: localhost:3000
Keep-Alive: 300
Connection: keep-alive
EOS
    assert_equal 'cool=thing', request.env['QUERY_STRING']
    assert_equal '/page?cool=thing', request.env['REQUEST_URI']
    assert_equal '/page', request.env['REQUEST_PATH']
  end
  
  def test_parse_post_data
    request = R(<<-EOS.chomp, true)
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

    assert_equal 'POST', request.env['REQUEST_METHOD']
    assert_equal '/postit', request.env['REQUEST_URI']
    assert_equal 'text/html', request.env['CONTENT_TYPE']
    assert_equal '37', request.env['CONTENT_LENGTH']
    assert_equal 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5', request.env['HTTP_ACCEPT']
    assert_equal 'en-us,en;q=0.5', request.env['HTTP_ACCEPT_LANGUAGE']
    request.body.rewind
    assert_equal 'name=marc&email=macournoyer@gmail.com', request.body.read
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
    request = R(body, true)
    assert_equal '$Version="1"', request.env['HTTP_COOKIE2']
  end
  
  def test_long_query_string
    body = <<-EOS
GET /session?open_id_complete=1&nonce=ytPOcwni&nonce=ytPOcwni&openid.assoc_handle=%7BHMAC-SHA1%7D%7B473e38fe%7D%7BJTjJxA%3D%3D%7D&openid.identity=http%3A%2F%2Fmacournoyer.myopenid.com%2F&openid.mode=id_res&openid.op_endpoint=http%3A%2F%2Fwww.myopenid.com%2Fserver&openid.response_nonce=2007-11-29T01%3A19%3A35ZGA5FUU&openid.return_to=http%3A%2F%2Flocalhost%3A3000%2Fsession%3Fopen_id_complete%3D1%26nonce%3DytPOcwni%26nonce%3DytPOcwni&openid.sig=lPIRgwpfR6JAdGGnb0ZjcY%2FWjr8%3D&openid.signed=assoc_handle%2Cidentity%2Cmode%2Cop_endpoint%2Cresponse_nonce%2Creturn_to%2Csigned%2Csreg.email%2Csreg.nickname&openid.sreg.email=macournoyer%40yahoo.ca&openid.sreg.nickname=macournoyer HTTP/1.1
Host: localhost:3000
EOS
    request = R(body, true)
    
    assert_equal 'open_id_complete=1&nonce=ytPOcwni&nonce=ytPOcwni&openid.assoc_handle=%7BHMAC-SHA1%7D%7B473e38fe%7D%7BJTjJxA%3D%3D%7D&openid.identity=http%3A%2F%2Fmacournoyer.myopenid.com%2F&openid.mode=id_res&openid.op_endpoint=http%3A%2F%2Fwww.myopenid.com%2Fserver&openid.response_nonce=2007-11-29T01%3A19%3A35ZGA5FUU&openid.return_to=http%3A%2F%2Flocalhost%3A3000%2Fsession%3Fopen_id_complete%3D1%26nonce%3DytPOcwni%26nonce%3DytPOcwni&openid.sig=lPIRgwpfR6JAdGGnb0ZjcY%2FWjr8%3D&openid.signed=assoc_handle%2Cidentity%2Cmode%2Cop_endpoint%2Cresponse_nonce%2Creturn_to%2Csigned%2Csreg.email%2Csreg.nickname&openid.sreg.email=macournoyer%40yahoo.ca&openid.sreg.nickname=macournoyer', request.env['QUERY_STRING']
  end
  
  def test_stupid_content_length
    body = <<-EOS.chomp
POST / HTTP/1.1
Host: localhost:3000
Content-Length: 300

aye
EOS
    request = R(body, true)
    
    request.body.rewind
    assert_equal 'aye', request.body.read
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
    
    assert_faster_then 'Request parsing', 0.6 do
      R(body, true)
    end
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
    
    def R(raw, convert_line_feed=false)
      raw.gsub!("\n", "\r\n") if convert_line_feed
      request = Thin::Request.new({})
      request.parse raw
      request
    end
end