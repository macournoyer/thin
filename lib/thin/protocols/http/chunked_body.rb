module Thin
  module Protocols
    class Http
      # Same as Rack::Chunked::Body, but doesn't send the tail automaticaly.
      class ChunkedBody
        TERM = "\r\n"
        TAIL = "0#{TERM}#{TERM}"

        include Rack::Utils

        def initialize(body)
          @body = body
        end

        def each
          term = TERM
          @body.each do |chunk|
            size = bytesize(chunk)
            next if size == 0

            chunk = chunk.dup.force_encoding(Encoding::BINARY) if chunk.respond_to?(:force_encoding)
            yield [size.to_s(16), term, chunk, term].join
          end
        end

        def close
          @body.close if @body.respond_to?(:close)
        end
      end
    end
  end
end