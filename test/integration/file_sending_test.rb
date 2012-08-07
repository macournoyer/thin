require 'test_helper'

class FileSendingTest < IntegrationTestCase
  def test_small_file
    thin :env => "none"

    get "/small.txt"

    assert_status 200
    assert_header "Transfer-Encoding", "chunked"
    assert_equal File.size(File.expand_path("../../fixtures/small.txt", __FILE__)), @response.body.size
  end
  
  def test_big_file
    thin :env => "none"
    
    # Just big enough (>16K) to trigger EM mapped streamer.
    get "/big.txt"

    assert_status 200
    assert_header "Transfer-Encoding", "chunked"
    assert_equal File.size(File.expand_path("../../fixtures/big.txt", __FILE__)), @response.body.size
  end
end