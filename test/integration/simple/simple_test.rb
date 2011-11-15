require File.expand_path File.dirname(__FILE__) + '/../test_helper'

class SimpleTest < IntegrationTestCase
  def test_get
    get "/"
    
    assert_status 200
    assert_response_equals "hi!"
    assert_header "Content-Type", "text/plain"
  end
end