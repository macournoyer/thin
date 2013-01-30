require "thin/middlewares/threaded"
require "thin/middlewares/chunked"
require "thin/middlewares/stream_file"

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
  use Thin::Middlewares::Threaded, 20
end

map '/man' do
  # use Thin::Middlewares::Chunked
  use Thin::Middlewares::StreamFile
  run Rack::File.new("site/public/man")
end

use Rack::CommonLogger

run RackApp.new