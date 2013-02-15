module Thin
  # Legacy `throw :async` support.
  class CatchAsync
    def initialize(app)
      @app = app
    end

    def call(env)
      response = Response::ASYNC # `throw :async` will result in this response
      catch(:async) do
        response = @app.call(env)
      end
      response
    end
  end
end