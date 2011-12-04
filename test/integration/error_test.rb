require 'test_helper'

class ErrorTest < IntegrationTestCase
  def test_raise
    thin :log => "/dev/null"
    
    get "/raise"
    
    assert_status 500
  end
  
  def test_raise_without_middlewares
    thin :env => "none", :log => "/dev/null"
    
    get "/raise"
    
    assert_status 500
  end
  
  def test_logs_errors
    thin :env => "none"
    
    get "/raise"
    assert_match "Error processing request: ouch", read_log
  end
  
  def test_parse_error
    thin :log => "/dev/null"
    
    socket do |s|
      s.write "!!!WTH??YO111!\r\n"
      s.flush
      
      assert_match "HTTP/1.1 400 Bad Request", s.read
    end
  end
end