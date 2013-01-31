require "thin/fast_enumerator"

module Thin
  module Middlewares
    class Streaming
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)

        connection = env['thin.connection']

        responder = FastEnumerator.new(body)
        tick_loop = EM.tick_loop do
          if chunk = responder.next
            connection << chunk
          else
            :stop
          end
        end
        tick_loop.on_stop env['thin.close']

        headers['X-Thin-Deferred'] = 'yes'

        [status, headers, body]
      end
    end
  end
end