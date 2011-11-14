module Thin
  
end

require_relative "thin/version"
require_relative "thin/server"

app = proc do |env|
  [200, {"Content-Type" => "text/plain", "Content-Length" => 3}, ["hi!"]]
  # [200, {"Content-Type" => "text/plain"}, ["hi!"]]
end

Thin::Server.new(app).start(2)