require 'rubygems'
require File.dirname(__FILE__) + '/../lib/fart'
require 'test/unit'
require 'mocha'
require 'benchmark'

class TestRequest < Fart::Request
  def initialize(path, verb='GET', params={})
    @path = path
    @verb = verb.to_s.upcase
    @params = params
    
    @body = "#{@verb} #{path} HTTP/1.1"
  end
end