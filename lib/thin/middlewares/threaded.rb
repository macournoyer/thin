module Thin
  module Middlewares
    # Has to be the first middleware
    class Threaded
      def initialize(app, pool_size=20)
        @app = app
        EM.threadpool_size = pool_size
      end

      def call(env)
        env['rack.multithread'] = true

        EM.defer(proc { @app.call(env) }, env['thin.process'])

        [-1, {}, []]
      end
    end
  end
end