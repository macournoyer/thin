# Benchmark to compare Thin performance against
# previous Thin version (the one installed as a gem).
#
# Run with:
#
#  ruby previous.rb [num of request]
#
require 'rubygems'
require 'rack'
require File.dirname(__FILE__) + '/utils'

request = (ARGV[0] || 1000).to_i # Number of request to send (ab -n option)

benchmark %w(current gem), request
