# Run with: rackup -s thin
# Then browse to http://localhost:9292
# Check Rack::Builder doc for more details on this file format:
#  http://rack.rubyforge.org/doc/classes/Rack/Builder.html

require File.dirname(__FILE__) + '/../lib/thin'
require 'rack/lobster'

run Rack::Lobster.new
