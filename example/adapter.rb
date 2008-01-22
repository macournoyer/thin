require 'rubygems'
require 'thin'

class SimpleAdapter
  def call(env)
    [
      200,
      { 'Content-Type' => 'text/plain' },
      ["hello!\n"]
    ]
  end
end

app = Rack::URLMap.new('/test'  => SimpleAdapter.new,
                       '/files' => Rack::File.new('.'))

Thin::Server.new('0.0.0.0', 3000, app).start!