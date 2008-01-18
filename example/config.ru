# Run with: rackup -s thin
# Then browse to http://localhost:9292
# Check Rack::Builder doc for more details on this file format:
#  http://rack.rubyforge.org/doc/classes/Rack/Builder.html

require File.dirname(__FILE__) + '/../lib/thin'

app = proc do |env|
  [
    200,
    {'Content-Type' => 'text/html'},
    ['hi!']
  ]
end

run app