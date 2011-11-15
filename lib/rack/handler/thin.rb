require "thin"

module Rack
  module Handler
    class Thin
      def self.run(app, options={})
        server = ::Thin::Server.new(app,
                                    options[:Host] || '0.0.0.0',
                                    options[:Port] || 8080)
        yield server if block_given?
        server.start(options[:workers])
      end

      def self.valid_options
        {
          "Host=HOST" => "Hostname to listen on (default: localhost)",
          "Port=PORT" => "Port to listen on (default: 8080)",
          "workers=NUMBER" => "Number of workers to start (default: number of processors)"
        }
      end
    end
  end
end
