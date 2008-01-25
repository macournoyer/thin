require File.dirname(__FILE__) + '/../lib/thin'

class SimpleAdapter
  def call(env)
    body = ["hello!"]
    [
      200,
      {
        'Content-Type'   => 'text/plain',
        'Content-Length' => body.join.size.to_s,
      },
      body
    ]
  end
end

app = Rack::URLMap.new('/test'  => SimpleAdapter.new,
                       '/files' => Rack::File.new('.'))

Thin::Server.start('0.0.0.0', 3000, app)