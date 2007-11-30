module Thin
  NAME           = 'thin'.freeze
  VERSION        = '0.1'.freeze
  SERVER         = "#{NAME} #{VERSION}".freeze
  
  # The basic max request size we'll try to read.
  CHUNK_SIZE     = 16 * 1024
  
  CONTENT_LENGTH = 'Content-Length'.freeze
  CONTENT_TYPE   = 'Content-Type'.freeze
  
  HEADER_FORMAT  = "%s: %s\r\n".freeze
  LF             = "\n".freeze

  # The standard empty 404 response when the request was not processed.
  ERROR_404_RESPONSE = <<-EOS.freeze
HTTP/1.1 404 Not Found
Connection: close
Server: #{SERVER}
Content-Type: text/html

<html><h1>Page not found</h1></html>
EOS
  
  ERROR_400_RESPONSE = <<-EOS.freeze
HTTP/1.1 400 Bad Request
Connection: close
Server: #{SERVER}
Content-Type: text/html

<html><h1>Bad request</h1></html>
EOS
end
