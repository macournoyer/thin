$: << File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'timeout'
require 'stringio'

require 'rubygems'
require 'eventmachine'

require 'thin/version'
require 'thin/consts'
require 'thin/statuses'
module Thin
  autoload :Logging,      'thin/logging'
  autoload :Daemonizable, 'thin/daemonizing'
  autoload :Connection,   'thin/connection'
  autoload :Server,       'thin/server'
  autoload :Request,      'thin/request'
  autoload :Headers,      'thin/headers'
  autoload :Response,     'thin/response'
end

require 'rack'
module Rack
  module Handler
    autoload :Thin, 'rack/handler/thin'
  end
end
