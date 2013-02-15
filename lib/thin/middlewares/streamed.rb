module Thin
  # Stream the response body.
  # Each yielded chunk will be sent on an EventMachine loop tick.
  # WARNING: you must disable Rack::Lock (config.threadsafe! in Rails)
  #          and make sure your body#each code is thread safe for this to work.
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
      tick_loop.on_stop { connection.close }

      headers['X-Thin-Defer'] = 'body'

      [status, headers, body]
    end
  end
end