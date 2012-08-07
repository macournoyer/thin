require "thin/async"

class App
  def call(env)
    request = Rack::Request.new(env)
    
    case request.path_info
    when "/"
      Rack::Response.new do |response|
        response.write "ok"
      end.finish
      
    when "/env"
      Rack::Response.new do |response|
        env.each_pair do |key, value|
          response.write "#{key}: #{value}\n"
        end
        response.write "\n" + request.body.read
      end.finish
      
    when "/eval"
      Rack::Response.new do |response|
        response.write eval(request["code"]).to_s
      end.finish
      
    when "/raise"
      raise "ouch"
      
    when "/exit"
      exit!
      
    when "/sleep"
      sleep request["sec"].to_f
      
    when "/async"
      Thin::AsyncResponse.new(env) do |response|
        response << "one\n"
        EM.next_tick do
          response << "two\n"
          response.done # close the connection
        end
      end.finish
      
    else
      Rack::Response.new do |response|
        response.status = 404
        response.write "not found"
      end.finish
      
    end
  end
end

use Rack::Static, :urls => ["/small.txt", "/big.txt"],
                  :root => File.expand_path("../../fixtures", __FILE__)

run App.new