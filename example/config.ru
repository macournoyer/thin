# Run with: rackup -s thin
# Then browse to http://localhost:9292
# Check Rack::Builder doc for more details on this file format:
#  http://rack.rubyforge.org/doc/classes/Rack/Builder.html

require File.dirname(__FILE__) + '/../lib/thin'

app = proc do |env|
  # Response body has to respond to each and yield strings
  # See Rack specs for more info: http://rack.rubyforge.org/doc/files/SPEC.html
  body = ['hi!']
  
  [
    200,                                        # Status code
    {
      'Content-Type' => 'text/html',            # Reponse headers
      'Content-Length' => body.join.size.to_s
    },
    body                                        # Body of the response
  ]
end

run app