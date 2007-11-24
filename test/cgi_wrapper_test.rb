require File.dirname(__FILE__) + '/test_helper'
require 'cgi/session'

class CGIWrapperTest < Test::Unit::TestCase
  
  def test_set_cookies_output_cookies
    request = TestRequest.new('/', 'GET')
    response = nil # not needed for this test
    output_headers = {}
    
    cgi = Thin::CGIWrapper.new(request, response) 
    session = CGI::Session.new(cgi, 'database_manager' => CGI::Session::MemoryStore)
    cgi.send_cookies(output_headers)
    
    assert(output_headers.has_key?("Set-Cookie"))
    assert_equal("_session_id="+session.session_id+"; path=", output_headers["Set-Cookie"])
  end
end