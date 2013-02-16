module Thin
  class StreamFile
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if body.respond_to?(:to_path)
        chunked = chunked?(env)
        connection = env['thin.connection']

        if chunked
          headers.delete('Content-Length')
          headers['Transfer-Encoding'] = 'chunked'
        end

        headers['X-Thin-Defer'] = 'close'

        env['thin.on_send'] = proc do
          send_file connection, body.to_path, chunked
        end
      end

      [status, headers, []]
    end

    def chunked?(env)
      env['HTTP_VERSION'] != 'HTTP/1.0'
    end

    def send_file(connection, filename, chunked)
      deferrable = connection.stream_file_data filename, :http_chunks => chunked

      callback = proc { connection.close }
      deferrable.callback(&callback)
      deferrable.errback(&callback)
    end
  end
end
