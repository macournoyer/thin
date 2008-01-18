# Simple benchmark to compare Thin performance against
# other webservers supported by Rack.
#
# Run with:
#
#  ruby simple.rb [num of request]
#
require File.dirname(__FILE__) + '/../lib/thin'
require File.dirname(__FILE__) + '/utils'

request = (ARGV[0] || 1000).to_i # Number of request to send (ab -n option)

benchmark %w(WEBrick Mongrel EMongrel Thin), request
