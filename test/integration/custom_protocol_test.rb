require 'test_helper'

class CustomProtocolTest < IntegrationTestCase
  def test_echo
    thin do
      require File.expand_path("../../fixtures/echo", __FILE__)
      listen PORT, :protocol => "Echo"
    end
    
    socket do |s|
      s.write "hi"
      assert_equal "hi", s.read
    end
  end
end