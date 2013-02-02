module Thin
  # Stream the response body.
  # Each yielded chunk will be sent on EM next tick.
  # WARNING: you must disable Rack::Lock (config.threadsafe! in Rails) for this to work.
  class Streamed
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