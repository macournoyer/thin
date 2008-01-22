module Thin
  # Rack adapter to log stats to a Rack application
  module Stats
    class Adapter
      def initialize(app, path='/stats')
        @app  = app
        @path = path
        
        @requests          = 0
        @requests_finished = 0
        @start_time        = Time.now
      end
      
      def call(env)
        if env['PATH_INFO'].index(@path) == 0
          serve(env)
        else
          log(env) { @app.call(env) }
        end
      end
      
      def log(env)
        @requests += 1
        @server = env['SERVER_SOFTWARE']
        request_started_at = Time.now
        
        response = yield
        
        @requests_finished += 1
        @last_request_path = env['PATH_INFO']
        @last_request_time = Time.now - request_started_at
        
        response
      end
      
      def serve(env)
        body = '<html><body>'
        body << '<h1>Server stats</h1>'
        body << '<ul>'
        body << "<li>#{@requests} requests</li>"
        body << "<li>#{@requests_finished} requests finished</li>"
        body << "<li>#{@requests - @requests_finished} errors</li>"
        body << "<li>#{Time.now - @start_time} uptime</li>"
        body << "<li>Running on #{@server}</li>"
        body << '</ul>'
        body << '<h2>Last request</h2>'
        body << '<ul>'
        body << "<li>#{@last_request_path}</li>"
        body << "<li>Took #{@last_request_time} sec</li>"
        body << '</ul>'
        body << '</body></html>'
        
        [
          200,
          {
            'Content-Type' => 'text/html',
            'Content-Length' => body.size.to_s
          },
          body
        ]
      end
    end
  end
end