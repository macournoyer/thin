require 'spec_helper'

# Require mongrel so we can test that Thin parser don't clash w/ Mongrel parser.
begin
  require 'mongrel'
rescue LoadError
  warn "Install mongrel to test compatibility w/ it"
end

describe Request, 'parser' do
  it 'should include basic headers' do
    request = R("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
    expect(request.env['SERVER_PROTOCOL']).to eq('HTTP/1.1')
    expect(request.env['REQUEST_PATH']).to eq('/')
    expect(request.env['HTTP_VERSION']).to eq('HTTP/1.1')
    expect(request.env['REQUEST_URI']).to eq('/')
    expect(request.env['GATEWAY_INTERFACE']).to eq('CGI/1.2')
    expect(request.env['REQUEST_METHOD']).to eq('GET')
    expect(request.env["rack.url_scheme"]).to eq('http')
    expect(request.env['FRAGMENT'].to_s).to be_empty
    expect(request.env['QUERY_STRING'].to_s).to be_empty
    
    expect(request).to validate_with_lint
  end
  
  it 'should upcase headers' do
    request = R("GET / HTTP/1.1\r\nX-Invisible: yo\r\n\r\n")
    expect(request.env['HTTP_X_INVISIBLE']).to eq('yo')
  end
  
  it 'should not prepend HTTP_ to Content-Type and Content-Length' do
    request = R("POST / HTTP/1.1\r\nHost: localhost\r\nContent-Type: text/html\r\nContent-Length: 2\r\n\r\naa")
    expect(request.env.keys).not_to include('HTTP_CONTENT_TYPE', 'HTTP_CONTENT_LENGTH')
    expect(request.env.keys).to include('CONTENT_TYPE', 'CONTENT_LENGTH')
    
    expect(request).to validate_with_lint
  end
  
  it 'should raise error on invalid request line' do
    expect { R("GET / SsUTF/1.1") }.to raise_error(InvalidRequest)
    expect { R("GET / HTTP/1.1yousmelllikecheeze") }.to raise_error(InvalidRequest)
  end
  
  it 'should support fragment in uri' do
    request = R("GET /forums/1/topics/2375?page=1#posts-17408 HTTP/1.1\r\nHost: localhost\r\n\r\n")

    expect(request.env['REQUEST_URI']).to eq('/forums/1/topics/2375?page=1')
    expect(request.env['PATH_INFO']).to eq('/forums/1/topics/2375')
    expect(request.env['QUERY_STRING']).to eq('page=1')
    expect(request.env['FRAGMENT']).to eq('posts-17408')
    
    expect(request).to validate_with_lint
  end
  
  it 'should parse path with query string' do
    request = R("GET /index.html?234235 HTTP/1.1\r\nHost: localhost\r\n\r\n")
    expect(request.env['REQUEST_PATH']).to eq('/index.html')
    expect(request.env['QUERY_STRING']).to eq('234235')
    expect(request.env['FRAGMENT']).to be_nil
    
    expect(request).to validate_with_lint
  end
  
  it 'should parse headers from GET request' do
    request = R(<<-EOS, true)
GET / HTTP/1.1
Host: myhost.com:3000
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9
Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Cookie: mium=7
Keep-Alive: 300
Connection: keep-alive

EOS
    expect(request.env['HTTP_HOST']).to eq('myhost.com:3000')
    expect(request.env['SERVER_NAME']).to eq('myhost.com')
    expect(request.env['SERVER_PORT']).to eq('3000')
    expect(request.env['HTTP_COOKIE']).to eq('mium=7')

    expect(request).to validate_with_lint
  end

  it 'should parse POST request with data' do
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

    expect(request.env['REQUEST_METHOD']).to eq('POST')
    expect(request.env['REQUEST_URI']).to eq('/postit')
    expect(request.env['CONTENT_TYPE']).to eq('text/html')
    expect(request.env['CONTENT_LENGTH']).to eq('37')
    expect(request.env['HTTP_ACCEPT']).to eq('text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5')
    expect(request.env['HTTP_ACCEPT_LANGUAGE']).to eq('en-us,en;q=0.5')

    request.body.rewind
    expect(request.body.read).to eq('name=marc&email=macournoyer@gmail.com')
    expect(request.body.class).to eq(StringIO)

    expect(request).to validate_with_lint
  end

  it 'should not fuck up on stupid fucked IE6 headers' do
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
Content-Length: 1
Content-Type: application/x-www-form-urlencoded
Cookie: _refactormycode_session_id=a1b2n3jk4k5; flash=%7B%7D
Cookie2: $Version="1"

a
EOS
    request = R(body, true)
    expect(request.env['HTTP_COOKIE2']).to eq('$Version="1"')

    expect(request).to validate_with_lint
  end

  it 'shoud accept long query string' do
    body = <<-EOS
GET /session?open_id_complete=1&nonce=ytPOcwni&nonce=ytPOcwni&openid.assoc_handle=%7BHMAC-SHA1%7D%7B473e38fe%7D%7BJTjJxA%3D%3D%7D&openid.identity=http%3A%2F%2Fmacournoyer.myopenid.com%2F&openid.mode=id_res&openid.op_endpoint=http%3A%2F%2Fwww.myopenid.com%2Fserver&openid.response_nonce=2007-11-29T01%3A19%3A35ZGA5FUU&openid.return_to=http%3A%2F%2Flocalhost%3A3000%2Fsession%3Fopen_id_complete%3D1%26nonce%3DytPOcwni%26nonce%3DytPOcwni&openid.sig=lPIRgwpfR6JAdGGnb0ZjcY%2FWjr8%3D&openid.signed=assoc_handle%2Cidentity%2Cmode%2Cop_endpoint%2Cresponse_nonce%2Creturn_to%2Csigned%2Csreg.email%2Csreg.nickname&openid.sreg.email=macournoyer%40yahoo.ca&openid.sreg.nickname=macournoyer HTTP/1.1
Host: localhost:3000

EOS
    request = R(body, true)

    expect(request.env['QUERY_STRING']).to eq('open_id_complete=1&nonce=ytPOcwni&nonce=ytPOcwni&openid.assoc_handle=%7BHMAC-SHA1%7D%7B473e38fe%7D%7BJTjJxA%3D%3D%7D&openid.identity=http%3A%2F%2Fmacournoyer.myopenid.com%2F&openid.mode=id_res&openid.op_endpoint=http%3A%2F%2Fwww.myopenid.com%2Fserver&openid.response_nonce=2007-11-29T01%3A19%3A35ZGA5FUU&openid.return_to=http%3A%2F%2Flocalhost%3A3000%2Fsession%3Fopen_id_complete%3D1%26nonce%3DytPOcwni%26nonce%3DytPOcwni&openid.sig=lPIRgwpfR6JAdGGnb0ZjcY%2FWjr8%3D&openid.signed=assoc_handle%2Cidentity%2Cmode%2Cop_endpoint%2Cresponse_nonce%2Creturn_to%2Csigned%2Csreg.email%2Csreg.nickname&openid.sreg.email=macournoyer%40yahoo.ca&openid.sreg.nickname=macournoyer')

    expect(request).to validate_with_lint
  end
  
  it 'should parse even with stupid Content-Length' do
    body = <<-EOS.chomp
POST / HTTP/1.1
Host: localhost:3000
Content-Length: 300

aye
EOS
    request = R(body, true)

    request.body.rewind
    expect(request.body.read).to eq('aye')
  end
  
  it "should parse ie6 urls" do
    %w(/some/random/path"
       /some/random/path>
       /some/random/path<
       /we/love/you/ie6?q=<"">
       /url?<="&>="
       /mal"formed"?
    ).each do |path|
      parser     = HttpParser.new
      req        = {}
      sorta_safe = %(GET #{path} HTTP/1.1\r\n\r\n)
      nread      = parser.execute(req, sorta_safe, 0)

      expect(sorta_safe.size).to eq(nread - 1) # Ragel 6 skips last linebreak
      expect(parser).to be_finished
      expect(parser).not_to be_error
    end
  end
  
  it "should parse absolute request URI" do
    request = R(<<-EOS, true)
GET http://localhost:3000/hi?qs#f HTTP/1.1
Host: localhost:3000

EOS
    
    expect(request.env['PATH_INFO']).to eq('/hi')
    expect(request.env['REQUEST_PATH']).to eq('/hi')
    expect(request.env['REQUEST_URI']).to eq('/hi?qs')
    expect(request.env['HTTP_VERSION']).to eq('HTTP/1.1')
    expect(request.env['REQUEST_METHOD']).to eq('GET')
    expect(request.env["rack.url_scheme"]).to eq('http')
    expect(request.env['FRAGMENT'].to_s).to eq("f")
    expect(request.env['QUERY_STRING'].to_s).to eq("qs")

    expect(request).to validate_with_lint
  end


  it "should fails on heders larger then MAX_HEADER" do
    expect { R("GET / HTTP/1.1\r\nFoo: #{'X' * Request::MAX_HEADER}\r\n\r\n") }.to raise_error(InvalidRequest)
  end

  it "should fail when total request vastly exceeds specified CONTENT_LENGTH" do
    proc do
      R(<<-EOS, true)
POST / HTTP/1.1
Host: localhost:3000
Content-Length: 300

#{'X' * 300_000}
EOS
    end.should raise_error(InvalidRequest)
  end

  it "should default SERVER_NAME to localhost" do
    request = R("GET / HTTP/1.1\r\n\r\n")
    expect(request.env['SERVER_NAME']).to eq("localhost")
  end

  it 'should normalize http_fields' do
    [ "GET /index.html HTTP/1.1\r\nhos-t: localhost\r\n\r\n",
      "GET /index.html HTTP/1.1\r\nhOs_t: localhost\r\n\r\n",
      "GET /index.html HTTP/1.1\r\nhoS-T: localhost\r\n\r\n"
    ].each { |req_str|
      parser     = HttpParser.new
      req        = {}
      nread      = parser.execute(req, req_str, 0)
      expect(req).to have_key('HTTP_HOS_T')
    }
  end
  
  it "should parse PATH_INFO with semicolon" do
    qs = "QUERY_STRING"
    pi = "PATH_INFO"
    {
      "/1;a=b?c=d&e=f" => { qs => "c=d&e=f", pi => "/1;a=b" },
      "/1?c=d&e=f" => { qs => "c=d&e=f", pi => "/1" },
      "/1;a=b" => { qs => "", pi => "/1;a=b" },
      "/1;a=b?" => { qs => "", pi => "/1;a=b" },
      "/1?a=b;c=d&e=f" => { qs => "a=b;c=d&e=f", pi => "/1" },
      "*" => { qs => "", pi => "" },
    }.each do |uri, expect|
      parser     = HttpParser.new
      env        = {}
      nread      = parser.execute(env, "GET #{uri} HTTP/1.1\r\nHost: www.example.com\r\n\r\n", 0)

      expect(env[pi]).to eq(expect[pi])
      expect(env[qs]).to eq(expect[qs])
      expect(env["REQUEST_URI"]).to eq(uri)

      next if uri == "*"
      
      # Validate w/ Ruby's URI.parse
      uri = URI.parse("http://example.com#{uri}")
      expect(env[qs]).to eq(uri.query.to_s)
      expect(env[pi]).to eq(uri.path)
    end
  end
  
  it "should parse IE7 badly encoded URL" do
    body = <<-EOS.chomp
GET /H%uFFFDhnchenbrustfilet HTTP/1.1
Host: localhost:3000

EOS
    request = R(body, true)

    expect(request.env['REQUEST_URI']).to eq("/H%uFFFDhnchenbrustfilet")
  end
end