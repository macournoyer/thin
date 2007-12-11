$:.unshift File.dirname(__FILE__)

require 'rubygems'

require 'fileutils'
require 'timeout'
require 'stringio'
require 'eventmachine'

%w(
  version
  consts
  statuses
  mime_types
  logging
  daemonizing
  connection
  server
  request
  headers
  response
  handler
  cgi
  rails
).each { |l| require "thin/#{l}" }
