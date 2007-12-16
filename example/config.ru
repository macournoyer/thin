# Run with: rackup -s thin
require 'rack/lobster'
require '../lib/thin'

run Rack::Lobster.new
