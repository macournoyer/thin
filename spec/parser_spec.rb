require File.dirname(__FILE__) + '/spec_helper'

require 'digest/sha1'

describe HttpParser do
  before do
    @parser = HttpParser.new
    @req = {}
  end
  
  it "should parse a simple GET" do
    http = "GET / HTTP/1.1\r\n\r\n"
    nread = @parser.execute(@req, http, 0)

    http.length.should == nread
    @parser.should be_finished
    @parser.should_not be_error
    @parser.nread.should == nread
    
    @req['SERVER_PROTOCOL'].should == 'HTTP/1.1'
    @req['REQUEST_PATH'].should == '/'
    @req['HTTP_VERSION'].should == 'HTTP/1.1'
    @req['REQUEST_URI'].should == '/'
    @req['GATEWAY_INTERFACE'].should == 'CGI/1.2'
    @req['REQUEST_METHOD'].should == 'GET'
    @req['FRAGMENT'].should be_nil
    @req['QUERY_STRING'].should be_empty
    
    @parser.reset
    @parser.nread.should == 0
  end
  
  it "should handle bad headers properly" do
    expected = "GET / HTTP/1.1\r\naaaaaaaaaaaaa:++++++++++\r\n\r\n"
    nread = @parser.execute(@req, expected, 0)
    expected.length.should == nread
    @parser.should be_finished
    @parser.should_not be_error
  end
  
  it "should handle nasty pound header properly" do
    nasty_pound_header = "GET / HTTP/1.1\r\nX-SSL-Bullshit:   -----BEGIN CERTIFICATE-----\r\n\tMIIFbTCCBFWgAwIBAgICH4cwDQYJKoZIhvcNAQEFBQAwcDELMAkGA1UEBhMCVUsx\r\n\tETAPBgNVBAoTCGVTY2llbmNlMRIwEAYDVQQLEwlBdXRob3JpdHkxCzAJBgNVBAMT\r\n\tAkNBMS0wKwYJKoZIhvcNAQkBFh5jYS1vcGVyYXRvckBncmlkLXN1cHBvcnQuYWMu\r\n\tdWswHhcNMDYwNzI3MTQxMzI4WhcNMDcwNzI3MTQxMzI4WjBbMQswCQYDVQQGEwJV\r\n\tSzERMA8GA1UEChMIZVNjaWVuY2UxEzARBgNVBAsTCk1hbmNoZXN0ZXIxCzAJBgNV\r\n\tBAcTmrsogriqMWLAk1DMRcwFQYDVQQDEw5taWNoYWVsIHBhcmQYJKoZIhvcNAQEB\r\n\tBQADggEPADCCAQoCggEBANPEQBgl1IaKdSS1TbhF3hEXSl72G9J+WC/1R64fAcEF\r\n\tW51rEyFYiIeZGx/BVzwXbeBoNUK41OK65sxGuflMo5gLflbwJtHBRIEKAfVVp3YR\r\n\tgW7cMA/s/XKgL1GEC7rQw8lIZT8RApukCGqOVHSi/F1SiFlPDxuDfmdiNzL31+sL\r\n\t0iwHDdNkGjy5pyBSB8Y79dsSJtCW/iaLB0/n8Sj7HgvvZJ7x0fr+RQjYOUUfrePP\r\n\tu2MSpFyf+9BbC/aXgaZuiCvSR+8Snv3xApQY+fULK/xY8h8Ua51iXoQ5jrgu2SqR\r\n\twgA7BUi3G8LFzMBl8FRCDYGUDy7M6QaHXx1ZWIPWNKsCAwEAAaOCAiQwggIgMAwG\r\n\tA1UdEwEB/wQCMAAwEQYJYIZIAYb4QgEBBAQDAgWgMA4GA1UdDwEB/wQEAwID6DAs\r\n\tBglghkgBhvhCAQ0EHxYdVUsgZS1TY2llbmNlIFVzZXIgQ2VydGlmaWNhdGUwHQYD\r\n\tVR0OBBYEFDTt/sf9PeMaZDHkUIldrDYMNTBZMIGaBgNVHSMEgZIwgY+AFAI4qxGj\r\n\tloCLDdMVKwiljjDastqooXSkcjBwMQswCQYDVQQGEwJVSzERMA8GA1UEChMIZVNj\r\n\taWVuY2UxEjAQBgNVBAsTCUF1dGhvcml0eTELMAkGA1UEAxMCQ0ExLTArBgkqhkiG\r\n\t9w0BCQEWHmNhLW9wZXJhdG9yQGdyaWQtc3VwcG9ydC5hYy51a4IBADApBgNVHRIE\r\n\tIjAggR5jYS1vcGVyYXRvckBncmlkLXN1cHBvcnQuYWMudWswGQYDVR0gBBIwEDAO\r\n\tBgwrBgEEAdkvAQEBAQYwPQYJYIZIAYb4QgEEBDAWLmh0dHA6Ly9jYS5ncmlkLXN1\r\n\tcHBvcnQuYWMudmT4sopwqlBWsvcHViL2NybC9jYWNybC5jcmwwPQYJYIZIAYb4QgEDBDAWLmh0\r\n\tdHA6Ly9jYS5ncmlkLXN1cHBvcnQuYWMudWsvcHViL2NybC9jYWNybC5jcmwwPwYD\r\n\tVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NhLmdyaWQt5hYy51ay9wdWIv\r\n\tY3JsL2NhY3JsLmNybDANBgkqhkiG9w0BAQUFAAOCAQEAS/U4iiooBENGW/Hwmmd3\r\n\tXCy6Zrt08YjKCzGNjorT98g8uGsqYjSxv/hmi0qlnlHs+k/3Iobc3LjS5AMYr5L8\r\n\tUO7OSkgFFlLHQyC9JzPfmLCAugvzEbyv4Olnsr8hbxF1MbKZoQxUZtMVu29wjfXk\r\n\thTeApBv7eaKCWpSp7MCbvgzm74izKhu3vlDk9w6qVrxePfGgpKPqfHiOoGhFnbTK\r\n\twTC6o2xq5y0qZ03JonF7OJspEd3I5zKY3E+ov7/ZhW6DqT8UFvsAdjvQbXyhV8Eu\r\n\tYhixw1aKEPzNjNowuIseVogKOLXxWI5vAi5HgXdS0/ES5gDGsABo4fqovUKlgop3\r\n\tRA==\r\n\t-----END CERTIFICATE-----\r\n\r\n"

    lambda{@parser.execute(@req, nasty_pound_header, 0)}.should raise_error(InvalidRequest)
    # nasty_pound_header.length.should == nread
    # @parser.should be_finished
    # @parser.should_not be_error
  end
  
  it "should raise parse errors properly" do
    bad_http = "GET / SsUTF/1.1"

    error = false
    begin
      nread = @parser.execute(@req, bad_http, 0)
    rescue => details
      error = true
    end

    error.should be_true
    @parser.should_not be_finished
    @parser.should be_error
  end
  
  it "should handle fragments in url" do
    get = "GET /forums/1/topics/2375?page=1#posts-17408 HTTP/1.1\r\n\r\n"
    lambda{@parser.execute(@req, get, 0)}.should_not raise_error(InvalidRequest)
    @parser.should be_finished
    @req['REQUEST_URI'].should == '/forums/1/topics/2375?page=1'
    @req['FRAGMENT'].should == 'posts-17408'
  end
  
  # lame random garbage maker
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
  
  it "should raise errors for bad queries" do
    # then that large header names are caught
    10.times do |c|
      get = "GET /#{rand_data(10,120)} HTTP/1.1\r\nX-#{rand_data(1024, 1024+(c*1024))}: Test\r\n\r\n"
      lambda{@parser.execute({}, get, 0)}.should raise_error(InvalidRequest)
      @parser.reset
    end

    # then that large mangled field values are caught
    10.times do |c|
      get = "GET /#{rand_data(10,120)} HTTP/1.1\r\nX-Test: #{rand_data(1024, 1024+(c*1024), false)}\r\n\r\n"
      lambda{@parser.execute({}, get, 0)}.should raise_error(InvalidRequest)
      @parser.reset
    end

    # then large headers are rejected too
    get = "GET /#{rand_data(10,120)} HTTP/1.1\r\n"
    get << "X-Test: test\r\n" * (80 * 1024)
    lambda{@parser.execute({}, get, 0)}.should raise_error(InvalidRequest)
    @parser.reset

    # finally just that random garbage gets blocked all the time
    10.times do |c|
      get = "GET #{rand_data(1024, 1024+(c*1024), false)} #{rand_data(1024, 1024+(c*1024), false)}\r\n\r\n"
      lambda{@parser.execute({}, get, 0)}.should raise_error(InvalidRequest)
      @parser.reset
    end
  end
end
