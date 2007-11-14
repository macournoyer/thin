module Thin
  LOGGER = Logger.new(STDOUT)
  
  CHUNK_SIZE     = 16 * 1024
  VERSION        = '0.1'.freeze
  SERVER         = "Thin #{VERSION}".freeze
  
  CONTENT_LENGTH = 'Content-Length'.freeze
  CONTENT_TYPE   = 'Content-Type'.freeze

  # The standard empty 404 response for bad requests.
  ERROR_404_RESPONSE = <<-EOS.freeze
HTTP/1.1 404 Not Found
Connection: close
Server: #{SERVER}
Content-Type: text/html

<html><h1>Page not found</h1></html>
EOS
end
