module Thin
  # Like Rack::Chunk but support async responses
  # Make sure it is mounted before any middleware that wraps the body
  class Chunked
    include Rack::Utils

    # Same as Rack::Chunked::Body, but doesn't send the tail automaticaly.
    class Body < SimpleDelegator
      TERM = "\r\n"
      TAIL = "0#{TERM}#{TERM}"

      def initialize(body)
        super
        @body = body
      end

      def each
        term = TERM
        @body.each do |chunk|
          size = Rack::Utils.bytesize(chunk)
          next if size == 0

          chunk = chunk.dup.force_encoding(Encoding::BINARY) if chunk.respond_to?(:force_encoding)
          yield [size.to_s(16), term, chunk, term].join
        end

        if @body.respond_to?(:callback)
          @body.callback { yield TAIL }
        else
          yield TAIL
        end
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = HeaderHash.new(headers)

      if env['HTTP_VERSION'] == 'HTTP/1.0' ||
         STATUS_WITH_NO_ENTITY_BODY.include?(status) ||
         headers['Content-Length'] ||
         headers['Transfer-Encoding']
        [status, headers, body]
      else
        headers.delete('Content-Length')
        headers['Transfer-Encoding'] = 'chunked'
        [status, headers, Body.new(body)]
      end
    end
  end
end
