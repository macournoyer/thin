class RackApp
  def call(env)
    body = env.inspect

    # Response
    [
      200, # status code
      { 'Content-Type' => 'text/plain', 'Content-Length' => body.size.to_s }, # headers
      [body] # body
    ]
  end
end

map '/threaded' do
  use Thin::Threaded
end

map '/man' do
  use Thin::StreamFile
  run Rack::File.new("site/public/man")
end

use Thin::Streamed
use Rack::CommonLogger

run RackApp.new