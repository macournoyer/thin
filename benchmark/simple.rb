# Simple benchmark to compare Thin performance against
# other webservers supported by Rack.
#
# Run with:
#
#  ruby simple.rb [num of request]
#
require File.dirname(__FILE__) + '/../lib/thin'
require 'rack/lobster'

REQUEST = (ARGV[0] || 1000).to_i # Number of request to send (ab -n option)

def run(handler_name, c=1, n=REQUEST)
  server = fork do
    [STDOUT, STDERR].each { |o| o.reopen "/dev/null" }
  
    app = Rack::Lobster.new
    
    if handler_name == 'EMongrel'
      require 'swiftcore/evented_mongrel'
      handler_name = 'Mongrel'
    end
    handler = Rack::Handler.const_get(handler_name)
    handler.run app, :Host => '0.0.0.0', :Port => 7000
  end

  sleep 2

  out = `nice -n20 ab -c #{c} -n #{n} http://127.0.0.1:7000/ 2> /dev/null`

  Process.kill('SIGKILL', server)
  Process.wait
  
  if requests = out.match(/^Requests.+?(\d+\.\d+)/)
    failed = out.match(/^Failed requests.+?(\d+)$/)[1]
    "#{requests[1].to_s.ljust(9)} #{failed}"
  else
    'ERROR'
  end
end

puts 'server     request   concurrency   req/s     failures'
puts '=' * 53
[1, 10, 100].each do |c|
  %w(WEBrick Mongrel EMongrel Thin).each do |server|
    puts "#{server.ljust(8)}   #{REQUEST}      #{c.to_s.ljust(4)}          #{run(server, c)}"
  end
end