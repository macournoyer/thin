# usage: rackup
require "sc"

run Rack::Cascade.new([Rack::File.new("public"), Sc])