module Thin
  module Middlewares
    class Async
      class Callback
        def initialize(method, env)
          @method = method
          @env = env
        end

        def call(response)
          @method.call(response, @env)
        end
      end

      def initialize(app, &builder)
        @app = app
        @builder = Rack::Builder.new(&builder)
      end

      def call(env)
        # Connection may be closed unless the App#call response was a [-1, ...]
        # It should be noted that connection objects will linger until this 
        # callback is no longer referenced, so be tidy!
        env['async.callback'] = Callback.new(method(:async_call), env)

        @app.call(env)
      end

      def async_call(response, env)
        # TODO refactor this to prevent creating a proc on each call
        @builder.run(proc { |env| response })
        status, headers, body = *@builder.call(env)

        connection = env['thin.connection']
        reset = connection.method(:reset)
        headers['X-Thin-Deferred'] = 'yes'

        body.callback(&reset) if body.respond_to?(:callback)
        body.errback(&reset) if body.respond_to?(:errback)

        connection.send_response [status, headers, body]
      end
    end
  end
end