module Thin
  # Legacy `throw :async` support.
  class CatchAsync
    # Template async response.
    MARKER = [-1, {}, []].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      response = MARKER # `throw :async` will result in this response
      catch(:async) do
        response = @app.call(env)
      end
      response
    end
  end
end