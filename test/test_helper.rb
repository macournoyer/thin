require 'rubygems'
require File.dirname(__FILE__) + '/../lib/thin'
require 'test/unit'
require 'mocha'
require 'benchmark'

Thin::LOGGER = Logger.new(nil)

class TestRequest < Thin::Request
  def initialize(path, verb='GET', params={})
    @path = path
    @verb = verb.to_s.upcase
    @params = params
    
    @body = "#{@verb} #{path} HTTP/1.1"
  end
end