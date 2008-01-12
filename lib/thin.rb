$: << File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'timeout'
require 'stringio'

require 'rubygems'
require 'eventmachine'

require 'thin/version'
require 'thin/statuses'

module Thin
  NAME    = 'thin'.freeze
  SERVER  = "#{NAME} #{VERSION::STRING} codename #{VERSION::CODENAME}".freeze  
  
  autoload :Cluster,      'thin/cluster'
  autoload :Connection,   'thin/connection'
  autoload :Daemonizable, 'thin/daemonizing'
  autoload :Logging,      'thin/logging'
  autoload :Headers,      'thin/headers'
  autoload :Request,      'thin/request'
  autoload :Response,     'thin/response'
  autoload :Server,       'thin/server'
end

require 'rack'

module Rack
  module Handler
    autoload :Thin, 'rack/handler/thin'
  end
  module Adapter
    autoload :Rails, 'rack/adapter/rails'
  end
end
