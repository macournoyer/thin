require File.dirname(__FILE__) + '/../test_helper'
require 'net/http'

class IntegrationTestCase < Test::Unit::TestCase
  def setup
    root = File.expand_path('../../..', __FILE__)
    @pid = fork { exec "ruby -I#{root}/lib #{root}/bin/thin config.ru" }

    tries = 0
    while !File.exist?("#{root}/thin.pid") || tries <= 20
      sleep 0.1
      tries += 1
    end
  end
  
  def teardown
    Process.kill "INT", @pid
    Process.waitall
  end
  
  def get(path)
    @response = Net::HTTP.get_response(URI.parse("http://localhost:3000" + path))
  end
  
  def assert_status(status)
    assert_equal status, @response.code.to_i
  end
  
  def assert_response_equals(string)
    assert_equal string, @response.body
  end
  
  def assert_header(key, value)
    assert_equal value, @response[key]
  end
end