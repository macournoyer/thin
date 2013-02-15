module Thin
  # Has to be the first middleware
  class Threaded
    def initialize(app, options={})
      @app = app
      EM.threadpool_size = options[:pool_size] if options.key?(:pool_size)
    end

    def call(env)
      env['rack.multithread'] = true

      EM.defer(proc { @app.call(env) }, env['thin.send'])

      Response::ASYNC
    end
  end
end