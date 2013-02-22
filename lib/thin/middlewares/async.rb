module Thin
  class Async
    class Callback
      def initialize(env, &callback)
        @env = env
        @callback = callback
      end

      def call(response)
        @callback.call(response, @env)
      end
    end

    # Middleware stack for an async response.
    # Since the response is already produced here, middleware that modify the request (env)
    # won't have any effect.
    class Stack
      def initialize(&builder)
        builder = Rack::Builder.new(&builder)
        builder.run(self)
        @app = builder.to_app
      end

      def call(env)
        @response
      end

      def call_with(env, response)
        @response = response
        @app.call(env)
      ensure
        @response = nil
      end
    end

    def initialize(app, &builder)
      @app = app
      @stack = Stack.new(&builder)
    end

    def call(env)
      env['async.callback'] = Callback.new(env) { |reponse, env| callback reponse, env }
      env['async.close'] = lambda { env['thin.connection'].close }

      @app.call(env)
    end

    def callback(response, env)
      status, headers, body = *@stack.call_with(env, response)

      env['thin.connection'].call [status, headers, body]
    end
  end
end