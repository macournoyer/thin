# Simple benchmark to compare Thin performance against
# other webservers supported by Rack.
#
# Run with:
#
#  ruby simple.rb [num of request] [print|graph] [concurrency levels]
#
require File.dirname(__FILE__) + '/../lib/thin'
require File.dirname(__FILE__) + '/utils'

request     = (ARGV[0] || 1000).to_i # Number of request to send (ab -n option)
output_type = (ARGV[1] || 'print')
levels      = eval(ARGV[2] || '[1, 10, 100]').to_a

benchmark output_type, %w(WEBrick Mongrel EMongrel Thin), request, levels
