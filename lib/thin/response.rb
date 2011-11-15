module Thin
  # A response sent to the client.
  class Response
    # Store HTTP header name-value pairs direcly to a string
    # and allow duplicated entries on some names.
    class Headers
      HEADER_FORMAT = "%s: %s\r\n".freeze
      ALLOWED_DUPLICATES = %w(Set-Cookie Set-Cookie2 Warning WWW-Authenticate).freeze

      def initialize
        @sent = {}
        @out = []
      end

      # Add <tt>key: value</tt> pair to the headers.
      # Ignore if already sent and no duplicates are allowed
      # for this +key+.
      def []=(key, value)
        if !@sent.has_key?(key) || ALLOWED_DUPLICATES.include?(key)
          @sent[key] = true
          value = case value
                  when Time
                    value.httpdate
                  when NilClass
                    return
                  else
                    value.to_s
                  end
          @out << HEADER_FORMAT % [key, value]
        end
      end

      def has_key?(key)
        @sent[key]
      end

      def to_s
        @out.join
      end
    end
    
    CONNECTION     = 'Connection'.freeze
    CLOSE          = 'close'.freeze
    SERVER         = 'Server'.freeze
    
    # Status code
    attr_accessor :status

    # Response body, must respond to +each+.
    attr_accessor :body

    # Headers key-value hash
    attr_reader   :headers
    
    def initialize
      @headers = Headers.new
      @status = 200
    end
    
    if System.ruby_18?

      # Ruby 1.8 implementation.
      # Respects Rack specs.
      #
      # See http://rack.rubyforge.org/doc/files/SPEC.html
      def headers=(key_value_pairs)
        key_value_pairs.each do |k, vs|
          vs.each { |v| @headers[k] = v.chomp } if vs
        end if key_value_pairs
      end

    else

      # Ruby 1.9 doesn't have a String#each anymore.
      # Rack spec doesn't take care of that yet, for now we just use
      # +each+ but fallback to +each_line+ on strings.
      # I wish we could remove that condition.
      # To be reviewed when a new Rack spec comes out.
      def headers=(key_value_pairs)
        key_value_pairs.each do |k, vs|
          next unless vs
          if vs.is_a?(String)
            vs.each_line { |v| @headers[k] = v.chomp }
          else
            vs.each { |v| @headers[k] = v.chomp }
          end
        end if key_value_pairs
      end

    end
    
    # Finish preparing the response.
    def finish
      @headers[CONNECTION] = CLOSE
      @headers[SERVER] = Thin::SERVER
    end
    
    # Top header of the response,
    # containing the status code and response headers.
    def head
      status_message = Rack::Utils::HTTP_STATUS_CODES[@status.to_i]
      "HTTP/1.1 #{@status} #{status_message}\r\n#{@headers.to_s}\r\n"
    end
    
    # Close any resource used by the response
    def close
      @body.close if @body.respond_to?(:close)
    end

    # Yields each chunk of the response.
    # To control the size of each chunk
    # define your own +each+ method on +body+.
    def each
      yield head
      if @body.is_a?(String)
        yield @body
      else
        @body.each { |chunk| yield chunk }
      end
    end
  end
end