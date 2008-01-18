require 'rack/lobster'

def run(handler_name, n=1000, c=1)
  server = fork do
    [STDOUT, STDERR].each { |o| o.reopen "/dev/null" }
      
    case handler_name
    when 'EMongrel'
      require 'swiftcore/evented_mongrel'
      handler_name = 'Mongrel'
    
    when 'gem' # Load the current Thin gem
      require 'thin'
      handler_name = 'Thin'
    
    when 'current' # Load the current Thin version under /lib
      require File.dirname(__FILE__) + '/../lib/thin'
      handler_name = 'Thin'
      
    end
    
    app = Rack::Lobster.new
    
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

def benchmark(servers, request, concurrency_levels=[1, 10, 100])
  puts 'server     request   concurrency   req/s     failures'
  puts '=' * 53
  concurrency_levels.each do |c|
    servers.each do |server|
      puts "#{server.ljust(8)}   #{request}      #{c.to_s.ljust(4)}          #{run(server, request, c)}"
    end
  end
end