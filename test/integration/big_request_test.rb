require 'test_helper'
require "thin/protocols/http"

class BigRequestTest < IntegrationTestCase
  def setup
    thin :env => "production" # to disable Lint
  end

  def test_big_body_is_stored_in_tempfile
    post "/eval?code=request.body.class", :big => "X" * (Thin::Protocols::Http::Request::MAX_BODY + 1)

    assert_status 200
    assert_response_equals "Tempfile"
  end

  def test_big_body_is_read_from_tempfile
    size = Thin::Protocols::Http::Request::MAX_BODY + 1
    post "/eval?code=request.body.read", :big => "X" * size

    assert_status 200
    assert_equal size + "big=".size, @response.body.size
  end

  def test_small_body_is_not_stored_in_tempfile
    post "/eval?code=request.body.class", :small => "X" * 1024

    assert_status 200
    assert_response_equals "StringIO"
  end
end
