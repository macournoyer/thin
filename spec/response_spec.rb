require File.dirname(__FILE__) + '/spec_helper'

describe Response do
  before do
    @response = Response.new
    @response.headers['Content-Type'] = 'text/html'
    @response.headers['Content-Length'] = '0'
    @response.body = ''
  end
  
  it 'should output headers' do
    @response.headers_output.should include("Content-Type: text/html", "Content-Length: 0", "Connection: close")
  end
  
  it 'should include server name header' do
    @response.headers_output.should include("Server: thin")
  end
  
  it 'should output head' do
    @response.head.should include("HTTP/1.1 200 OK", "Content-Type: text/html", "Content-Length: 0",
                                  "Connection: close", "\r\n\r\n")
  end
  
  it 'should allow duplicates in headers' do
    @response.headers['Set-Cookie'] = 'mium=7'
    @response.headers['Set-Cookie'] = 'hi=there'
    
    @response.head.should include("Set-Cookie: mium=7", "Set-Cookie: hi=there")
  end
  
  it 'should parse simple header values' do
    @response.headers = {
      'Host' => 'localhost'
    }
    
    @response.head.should include("Host: localhost")
  end
  
  it 'should parse multiline header values in several headers' do
    @response.headers = {
      'Set-Cookie' => "mium=7\nhi=there"
    }
    
    @response.head.should include("Set-Cookie: mium=7", "Set-Cookie: hi=there")
  end
  
  it 'should output body' do
    @response.body = '<html></html>'
    
    out = ''
    @response.each { |l| out << l }
    out.should include("\r\n\r\n<html></html>")
  end
  
  it "should be fast" do
    @response.body << <<-EOS
<html><head><title>Dir listing</title></head>
<body><h1>Listing stuff</h1><ul>
#{'<li>Hi!</li>' * 100}
</ul></body></html>
EOS
    
    proc { @response.each { |l| l } }.should be_faster_then(0.00011)
  end
  
  it "should be closeable" do
    @response.close
  end
end