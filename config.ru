class App
  def call(env)
    [200, {"Content-Type" => "text/plain", "Content-Length" => "3"}, ["hi!"]]
  end
end

use Rack::Static, :urls => ["/README", "/big.avi"]

run App.new