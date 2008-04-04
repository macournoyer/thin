$:.unshift File.expand_path(File.dirname(__FILE__))

require 'fileutils'
require 'timeout'
require 'stringio'

require 'rubygems'
require 'eventmachine'

require 'thin/version'
require 'thin/statuses'

module Thin
  autoload :Command,            'thin/command'
  autoload :Connection,         'thin/connection'
  autoload :Daemonizable,       'thin/daemonizing'
  autoload :Logging,            'thin/logging'
  autoload :Headers,            'thin/headers'
  autoload :Request,            'thin/request'
  autoload :Response,           'thin/response'
  autoload :Runner,             'thin/runner'
  autoload :Server,             'thin/server'
  autoload :Stats,              'thin/stats'
  
  module Backends
    autoload :Base,             'thin/backends/base'
    autoload :SwiftiplyClient,  'thin/backends/swiftiply_client'
    autoload :TcpServer,        'thin/backends/tcp_server'
    autoload :UnixServer,       'thin/backends/unix_server'
  end
  
  module Controllers
    autoload :Cluster,          'thin/controllers/cluster'
    autoload :Controller,       'thin/controllers/controller'
    autoload :Service,          'thin/controllers/service'
  end
end

require 'rack'
require 'rack/adapter/loader'

module Rack
  module Handler
    autoload :Thin, 'rack/handler/thin'
  end
  module Adapter
    autoload :Rails, 'rack/adapter/rails'
  end
end

# Load plugins at last so we can reopen any stuff
require 'thin/plugins'
Thin::Plugins.load
