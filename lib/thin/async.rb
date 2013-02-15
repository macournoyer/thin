module Thin
  class Async
    class Callback
      def initialize(method, env)
        @method = method
        @env = env
      end

      def call(response)
        @method.call(response, @env)
      end
    end

    def initialize(app, &builder)
      @app = app
      @builder = Rack::Builder.new(&builder)
    end

    def call(env)
      # Connection may be closed unless the App#call response was a [-1, ...]
      # It should be noted that connection objects will linger until this 
      # callback is no longer referenced, so be tidy!
      env['async.callback'] = Callback.new(method(:async_call), env)

      @app.call(env)
    end

    def async_call(response, env)
      # TODO refactor this to prevent creating a proc on each call
      @builder.run(proc { |env| response })
      status, headers, body = *@builder.call(env)

      headers['X-Thin-Defer'] = 'close'
      close = env['thin.close']

      body.callback(&reset) if body.respond_to?(:callback)
      body.errback(&reset) if body.respond_to?(:errback)

      env['thin.send'].call [status, headers, body]
    end
  end

  # Response whos body is sent asynchronously.
  # 
  # A nice wrapper around Thin's obscure async callback used to send response body asynchronously.
  # Which means you can send the response in chunks while allowing Thin to process other requests.
  # 
  # Crazy delicious with em-http-request for file upload, image processing, proxying, etc.
  # 
  # == _WARNING_
  # You should not use long blocking operations (Net::HTTP or slow shell calls) with this as it
  # will prevent the EventMachine event loop from running and block all other requests.
  #
  # Also disable the Rack::Lint middleware to use Thin's async feature since it requires sending
  # back an invalid status code to the server.
  # 
  # == Usage
  # Inside your Rack app #call(env):
  # 
  #     response = Thin::AsyncResponse.new(env)
  #     response.status = 201
  #     response.headers["X-Muffin-Mode"] = "ACTIVATED!"
  # 
  #     response << "this is ... "
  # 
  #     EM.add_timer(1) do
  #       # This will be sent to the client 1 sec later without blocking other requests.
  #       response << "async!"
  #       response.done
  #     end
  # 
  #     response.finish
  #
  class AsyncResponse
    include Rack::Response::Helpers

    class DeferrableBody
      include EM::Deferrable

      def initialize
        @queue = []
      end

      def call(body)
        @queue << body
        schedule_dequeue
      end

      def each(&blk)
        @body_callback = blk
        schedule_dequeue
      end
    
      private
        def schedule_dequeue
          return unless @body_callback
          EM.next_tick do
            next unless body = @queue.shift
            body.each do |chunk|
              @body_callback.call(chunk)
            end
            schedule_dequeue unless @queue.empty?
          end
        end
    end

    attr_reader :headers, :callback
    attr_accessor :status
    
    def initialize(env, status=200, headers={})
      @callback = env['async.callback']
      @closer = env['thin.close']
      @body = DeferrableBody.new
      @status = status
      @headers = headers
      @headers_sent = false
      
      yield self if block_given?
    end
    
    def send_headers(response=nil)
      return if @headers_sent
      @callback.call response || [@status, @headers, @body]
      @headers_sent = true
    end
    
    def write(body)
      send_headers
      @body.call(body.respond_to?(:each) ? body : [body])
    end
    alias :<< :write
    
    # Tell Thin the response is complete and the connection can be closed.
    def done(response=nil)
      send_headers(response)
      EM.next_tick { @closer.close }
    end
    
    # Tell Thin the response is gonna be sent asynchronously.
    # The status code of -1 is the magic trick here.
    def finish
      Response::ASYNC
    end
  end
end