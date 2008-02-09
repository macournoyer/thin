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
  
  module Connectors
    autoload :Connector,        'thin/connectors/connector'
    autoload :SwiftiplyClient,  'thin/connectors/swiftiply_client'
    autoload :TcpServer,        'thin/connectors/tcp_server'
    autoload :UnixServer,       'thin/connectors/unix_server'
  end
  
  module Controllers
    autoload :Cluster,          'thin/controllers/cluster'
    autoload :Controller,       'thin/controllers/controller'
    autoload :Service,          'thin/controllers/service'
  end
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
