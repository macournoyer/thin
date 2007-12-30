require File.dirname(__FILE__) + '/spec_helper'

describe Response do
  before do
    @response = Response.new
    @response.headers['Content-Type'] = 'text/html'
  end
  
  it 'should output headers' do
    @response.headers_output.should == "Content-Type: text/html\r\nContent-Length: 0\r\nConnection: close\r\n"
  end
  
  it 'should output head' do
    @response.head.should == "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
  end
  
  it 'should allow duplicates in headers' do
    @response.headers['Set-Cookie'] = 'mium=7'
    @response.headers['Set-Cookie'] = 'hi=there'
    
    @response.head.should == "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nSet-Cookie: mium=7\r\nSet-Cookie: hi=there\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
  end
  
  it 'should output body' do
    @response.body << '<html></html>'
    
    @response.to_s.should == "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 13\r\nConnection: close\r\n\r\n<html></html>"
  end
  
  it "should be faster then #{max_parsing_time = 0.04} ms" do
    @response.body << <<-EOS
<html><head><title>Dir listing</title></head>
<body><h1>Listing stuff</h1><ul>
#{'<li>Hi!</li>' * 100}
</ul></body></html>
EOS
    
    proc { @response.to_s }.should be_faster_then(max_parsing_time)
  end
end