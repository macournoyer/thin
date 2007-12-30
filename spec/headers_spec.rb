require File.dirname(__FILE__) + '/spec_helper'

describe Headers do
  before do
    @headers = Headers.new
  end
  
  it 'should allow duplicate on some fields' do
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    @headers.size.should == 2
  end
  
  it 'should overwrite value on non duplicate fields' do
    @headers['Host'] = 'this is unique'
    @headers['Host'] = 'so is this'
    @headers['Host'] = 'so this will overwrite ^'

    @headers['Host'].should == 'so this will overwrite ^'
  end
  
  it 'should return first header value' do
    @headers['Set-Cookie'] = 'hi'
    @headers['Set-Cookie'].should == 'hi'
  end
  
  it 'should output to string' do
    @headers['Host'] = 'localhost:3000'
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    @headers.to_s.should == "Host: localhost:3000\r\nSet-Cookie: twice\r\nSet-Cookie: is cooler the once\r\n"
  end
end