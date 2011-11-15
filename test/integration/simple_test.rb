require 'test_helper'

class SimpleTest < IntegrationTestCase
  def test_get
    thin
    
    get "/"
    
    assert_status 200
    assert_response_equals "ok"
    assert_header "Content-Type", "text/plain"
  end
end