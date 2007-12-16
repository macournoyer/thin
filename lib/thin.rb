$: << File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'timeout'
require 'stringio'

require 'rubygems'
require 'http11'
require 'eventmachine'

%w(
  version
  consts
  statuses
  logging
  daemonizing
  connection
  server
  request
  headers
  response
).each { |l| require "thin/#{l}" }

require 'rack'
require 'rack/handler/thin'