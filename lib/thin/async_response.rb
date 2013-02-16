module Thin
  class AsyncResponse
    class Body
      def initialize
        @queue = []
      end

      def <<(chunk)
        @queue << chunk
        schedule_dequeue
      end

      def each(&block)
        @callback = block
        schedule_dequeue
      end
  
      private
        def schedule_dequeue
          return unless @callback
          EM.next_tick do
            next unless chunk = @queue.shift
            @callback.call(chunk)
            schedule_dequeue unless @queue.empty?
          end
        end
    end

    def initialize(env, status=200, headers={})
      connection = env['thin.connection']
      # Fallback to thin.connection methods
      @callback = env['async.callback'] || connection.method(:send_response)
      @close = env['async.close'] || connection.method(:close)

      @status = status
      @headers = headers
      @body = Body.new
      @head_sent = false

      if block_given?
        yield self
        finish
      end
    end

    def send_head
      return if @head_sent
      EM.next_tick { @callback.call [@status, @headers, @body] }
      @head_sent = true
    end

    def write(data)
      send_head
      @body << data
    end
    alias << write

    def done
      send_head
      EM.next_tick @close
    end

    def finish
      [100, {'X-Thin-Defer' => 'response'}, []]
    end
  end
end