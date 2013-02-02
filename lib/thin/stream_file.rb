module Thin
  class StreamFile
    class FileStreamer
      def initialize(connection, filename, chunked)
        @connection = connection
        @filename = filename
        @chunked = chunked
      end

      def each
        deferrable = @connection.stream_file_data @filename, :http_chunks => @chunked
        
        reset = @connection.method(:reset)
        
        deferrable.callback(&reset)
        deferrable.errback(&reset)

        yield "" # Fake returning a chunk of the body
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if body.respond_to?(:to_path)
        chunked = chunked?(env)

        if chunked
          headers.delete('Content-Length')
          headers['Transfer-Encoding'] = 'chunked'
        end

        body = FileStreamer.new(env['thin.connection'], body.to_path, chunked)
        headers['X-Thin-Deferred'] = 'yes'
      end

      [status, headers, body]
    end

    def chunked?(env)
      env['HTTP_VERSION'] != 'HTTP/1.0'
    end
  end
end
