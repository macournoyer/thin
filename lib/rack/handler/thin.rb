module Rack
  module Handler
    # Rack Handler stricly to be able to use Thin through the rackup command.
    # To do so, simply require 'thin' in your Rack config file and run like this
    # 
    #   rackup --server thin
    # 
    class Thin
      def self.run(app, options={})
        server = ::Thin::Server.new(options[:Host] || '0.0.0.0',
                                    options[:Port] || 8080,
                                    app)
        yield server if block_given?
        server.start
      end
    end
  end
end
