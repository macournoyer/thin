module Thin
  NAME           = 'thin'.freeze
  SERVER         = "#{NAME} #{VERSION::STRING}".freeze
  
  # Versions for the protocoles used
  HTTP_VERSION   = 'HTTP/1.1'.freeze
  CGI_VERSION    = 'CGI/1.2'.freeze
  
  # The basic max request size we'll try to read.
  CHUNK_SIZE     = 16 * 1024
  
  MAX_HEADER     = 1024 * (80 + 32)
  
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
  
  # The standard empty 400 response when the request was invalid.
  ERROR_400_RESPONSE = <<-EOS.freeze
HTTP/1.1 400 Bad Request
Connection: close
Server: #{SERVER}
Content-Type: text/html

<html><h1>Bad request</h1></html>
EOS
end
