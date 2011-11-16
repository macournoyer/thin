require 'test_helper'

class BigRequestTest < IntegrationTestCase
  def setup
    thin :env => "production" # to disable Lint
  end
  
  def test_big_body_is_stored_in_tempfile
    post "/eval?code=request.body.class", :big => "X" * (1024 * (80 + 32) + 1)
    
    assert_status 200
    assert_response_equals "Tempfile"
  end
  
  def test_small_body_is_not_stored_in_tempfile
    post "/eval?code=request.body.class", :small => "X" * 1024
    
    assert_status 200
    assert_response_equals "StringIO"
  end
end