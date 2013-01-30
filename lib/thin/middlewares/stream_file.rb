module Thin
  module Middlewares
    class StreamFile
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)

        if body.respond_to?(:to_path)
          chunked = chunked?(env)

          send_file body.to_path,
                    env['thin.connection'],
                    chunked
          
          if chunked
            headers.delete('Content-Length')
            headers['Transfer-Encoding'] = 'chunked'
          end

          body = []
          headers['X-Thin-Deferred'] = 'yes'
        end

        [status, headers, body]
      end

      def chunked?(env)
        env['HTTP_VERSION'] != 'HTTP/1.0'
      end

      def send_file(filename, connection, chunked)
        deferrable = connection.stream_file_data filename, :http_chunks => chunked
        
        reset = connection.method(:reset)
        
        deferrable.callback(&reset)
        deferrable.errback(&reset)
      end
    end
  end
end