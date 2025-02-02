# frozen_string_literal: true

require "thin"
require "thin/server"
require "thin/logging"
require "thin/backends/tcp_server"

module Rack
  module Handler
    class Thin
      def self.run(app, **options)
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

        host = options.delete(:Host) || default_host
        port = options.delete(:Port) || 8080
        args = [host, port, app, options]

        server = ::Thin::Server.new(*args)
        yield server if block_given?

        server.start
      end

      def self.valid_options
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

        {
          "Host=HOST" => "Hostname to listen on (default: #{default_host})",
          "Port=PORT" => "Port to listen on (default: 8080)",
        }
      end
    end
  end
end

# rackup was removed in Rack 3, it is now a separate gem
if Object.const_defined?(:Rackup) && ::Rackup.const_defined?(:Handler)
  module Rackup
    module Handler
      module Thin
        class << ::Rack::Handler::Thin
        end
      end

      register :thin, ::Rackup::Handler::Thin
    end
  end
else
  do_register = Object.const_defined?(:Rack) && ::Rack.release < '3'
  ::Rack::Handler.register(:thin, ::Rack::Handler::Thin) if do_register
end
