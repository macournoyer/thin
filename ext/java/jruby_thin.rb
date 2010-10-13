require 'http11'

module Thin
  include Mongrel
  InvalidRequest = HttpParserError
end