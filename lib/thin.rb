$:.unshift File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'timeout'
require 'stringio'

require 'rubygems'
require 'eventmachine'

require 'thin/version'
require 'thin/statuses'

module Thin
  autoload :Cluster,      'thin/cluster'
  autoload :Command,      'thin/command'
  autoload :Connection,   'thin/connection'
  autoload :Controller,   'thin/controller'
  autoload :Daemonizable, 'thin/daemonizing'
  autoload :Logging,      'thin/logging'
  autoload :Headers,      'thin/headers'
  autoload :Request,      'thin/request'
  autoload :Response,     'thin/response'
  autoload :Runner,       'thin/runner'
  autoload :Server,       'thin/server'
  autoload :Service,      'thin/service'
  autoload :Stats,        'thin/stats'
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
